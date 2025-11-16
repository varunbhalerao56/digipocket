// olmo_format.dart
import 'prompt_format.dart';

/// OLMo-2 Instruct chat template:
/// <|endoftext|><|system|>\n{sys}\n<|user|>\n{user}\n<|assistant|>\n
class OlmoFormat extends PromptFormat {
  // Core turn markers
  static const String bos = '<|endoftext|>'; // also used as a stop
  static const String userTag = '<|user|>';
  static const String assistantTag = '<|assistant|>';
  static const String systemTag = '<|system|>';

  OlmoFormat()
    : super(
        PromptFormatType.olmo,
        inputSequence: userTag,
        outputSequence: assistantTag,
        systemSequence: systemTag,
        stopSequence: bos, // allow stopping on endoftext if emitted
      );

  /// Builds a single-turn prompt, optionally cueing assistant to speak next.
  String preparePrompt(
    String content, {
    String role = 'user',
    bool cueAssistant = true,
  }) {
    final roleTag = _roleToTag(role);
    final buf = StringBuffer()
      ..write(bos)
      ..write(roleTag)
      ..write('\n')
      ..write(content)
      ..write('\n');
    if (cueAssistant) {
      buf
        ..write(assistantTag)
        ..write('\n');
    }
    return buf.toString();
  }

  /// Maps 'user' | 'assistant' | 'system' → OLMo tags
  String _roleToTag(String role) {
    switch (role) {
      case 'assistant':
        return assistantTag;
      case 'system':
        return systemTag;
      case 'user':
      default:
        return userTag;
    }
  }

  /// Override: format a whole message list:
  /// [
  ///   {'role':'system','content':'You are helpful.'},
  ///   {'role':'user','content':'Hi'}
  /// ]
  /// →
  /// <|endoftext|><|system|>\nYou are helpful.\n<|user|>\nHi\n<|assistant|>\n
  @override
  String formatMessages(List<Map<String, dynamic>> messages) {
    final buf = StringBuffer()..write(bos);

    for (final m in messages) {
      final role = (m['role'] as String?)?.toLowerCase() ?? 'user';
      final content = (m['content'] ?? '').toString();

      buf
        ..write(_roleToTag(role))
        ..write('\n')
        ..write(content)
        ..write('\n');
    }

    // Cue the assistant to speak
    buf
      ..write(assistantTag)
      ..write('\n');

    return buf.toString();
  }

  /// Override: single string prompt helper (keeps base API working)
  @override
  String formatPrompt(String prompt) {
    // Equivalent to a single user turn + assistant cue
    return preparePrompt(prompt, role: 'user', cueAssistant: true);
  }
}
