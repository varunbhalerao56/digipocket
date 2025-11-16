import 'prompt_format.dart';

class ChatMLFormat extends PromptFormat {
  ChatMLFormat()
    : super(
        PromptFormatType.chatml,
        inputSequence: '<|im_start|>user\n',
        outputSequence: '<|im_start|>assistant\n',
        systemSequence: '<|im_start|>system\n',
        stopSequence: '<|im_end|>',
      );

  /// Prepares a single message with the ChatML format
  /// This is the atomic building block for formatting
  String prepareMessage(String content, String role) {
    return '<|im_start|>$role\n$content<|im_end|>\n';
  }

  /// Prepares a single prompt with the ChatML format
  /// [assistant] - if true, opens an assistant turn for generation
  String preparePrompt(
    String prompt, [
    String role = "user",
    bool assistant = true,
  ]) {
    String formatted = prepareMessage(prompt, role);
    if (assistant) {
      formatted += '<|im_start|>assistant\n';
    }
    return formatted;
  }

  @override
  String formatMessages(List<Map<String, dynamic>> messages) {
    StringBuffer buffer = StringBuffer();

    for (var message in messages) {
      final role = message['role'] as String;
      final content = message['content'] as String;

      // Use prepareMessage for consistency
      buffer.write(prepareMessage(content, role));
    }

    return buffer.toString();
  }

  @override
  String formatPrompt(String prompt) {
    return preparePrompt(prompt);
  }
}
