// lib/widgets/llama_chat_panel.dart
import 'dart:async';
import 'package:digipocket/feature/llama_cpp/llama_cpp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Minimal role/content pair for UI
class ChatMsg {
  final String role; // "system" | "user" | "assistant"
  String content;
  ChatMsg(this.role, this.content);
}

/// A drop-in chat panel that:
/// - shows a scrollable conversation box
/// - provides an input box to chat more
/// - streams tokens from llamaParent.stream into the output
///
/// Dependencies you must provide:
/// - an initialized [llamaParent] (already .init()'d)
class LlamaChatPanel extends HookWidget {
  final LlamaParent llamaParent;

  /// Optional system prompt shown only to the model (not rendered in UI).
  final String? systemPrompt;

  /// If true, appends an open assistant turn when formatting messages.
  /// For ChatML templates, this should be true.
  final bool addGenerationPrompt;

  const LlamaChatPanel({
    super.key,
    required this.llamaParent,
    this.systemPrompt,
    this.addGenerationPrompt = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = useMemoized(() => ChatMLFormat());

    final inputController = useTextEditingController();
    final scrollController = useScrollController();

    final history = useState<List<ChatMsg>>([]);
    final currentResponse = useState(StringBuffer());
    final awaiting = useState(false);

    // Initialize system message
    useEffect(() {
      if (systemPrompt != null && systemPrompt!.isNotEmpty) {
        history.value = [ChatMsg('system', systemPrompt!)];
      }
      return null;
    }, [systemPrompt]);

    // Auto-scroll helper
    void scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      });
    }

    // Listen to token stream
    useEffect(() {
      final tokenSub = llamaParent.stream.listen(
        (token) {
          currentResponse.value.write(token);

          // If there's no assistant message yet, add one with the first token
          if (history.value.isEmpty || history.value.last.role != 'assistant') {
            final updated = List<ChatMsg>.from(history.value)
              ..add(ChatMsg('assistant', token));
            history.value = updated;
          } else {
            // Update the existing assistant message
            final updated = List<ChatMsg>.from(history.value);
            updated.last.content = currentResponse.value.toString();
            history.value = updated;
          }
          scrollToBottom();
        },
        onError: (e) {
          debugPrint('STREAM ERROR: $e');
          awaiting.value = false;
        },
      );

      return tokenSub.cancel;
    }, [llamaParent]);

    // Listen to completion events
    useEffect(() {
      final completionSub = llamaParent.completions.listen((evt) {
        awaiting.value = false;
        if (!evt.success) {
          debugPrint('Completion failed for prompt: ${evt.promptId}');
        }
      });

      return completionSub.cancel;
    }, [llamaParent]);

    /// Build prompt from history using ChatML format
    String buildPromptFromHistory() {
      // Filter out empty assistant messages to avoid confusing the model
      final relevantHistory = history.value.where((m) {
        // Keep all non-assistant messages
        if (m.role != 'assistant') return true;
        // Only keep assistant messages that have content
        return m.content.isNotEmpty;
      }).toList();

      final msgs = relevantHistory
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      // Format all messages in the conversation
      var serialized = format.formatMessages(msgs);

      // Add generation prompt to open the assistant turn
      if (addGenerationPrompt) {
        serialized += format.outputSequence;
      }

      return serialized;
    }

    /// Send message
    Future<void> send() async {
      final text = inputController.text.trim();
      if (text.isEmpty || awaiting.value) return;
      inputController.clear();

      // Add user message ONLY
      // The assistant message will be added when the first token arrives
      final updated = List<ChatMsg>.from(history.value)
        ..add(ChatMsg('user', text));

      history.value = updated;
      awaiting.value = true;
      currentResponse.value.clear();
      scrollToBottom();

      // Send prompt to model
      final prompt = buildPromptFromHistory();
      debugPrint('-----------------------------------');
      debugPrint('Sending prompt:');
      debugPrint(prompt);
      debugPrint('-----------------------------------');
      await llamaParent.sendPrompt(prompt);
    }

    /// Clear chat history (keep system message)
    void clear() {
      history.value = history.value.where((m) => m.role == 'system').toList();
      awaiting.value = false;
      currentResponse.value.clear();
    }

    // Filter out system messages for display
    final visibleHistory = useMemoized(
      () => history.value.where((m) => m.role != 'system').toList(),
      [history.value],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OUTPUT BOX
        Container(
          constraints: const BoxConstraints(minHeight: 220, maxHeight: 360),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Scrollbar(
            controller: scrollController,
            child: ListView.builder(
              controller: scrollController,
              itemCount: visibleHistory.length,
              itemBuilder: (context, index) {
                final msg = visibleHistory[index];
                final isUser = msg.role == 'user';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.colorScheme.primary.withOpacity(0.10)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        child: SelectableText(
                          msg.content.isEmpty ? '…' : msg.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // INPUT BOX
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => send(),
                decoration: InputDecoration(
                  hintText: awaiting.value ? 'Generating…' : 'Type a message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                enabled: !awaiting.value,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: awaiting.value ? null : send,
              child: const Text('Send'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: awaiting.value ? null : clear,
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}
