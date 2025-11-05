// // lib/new_src/formats/lfm2_format.dart
// import 'dart:convert';
// import 'prompt_format.dart';
//
// /// LFM2 chat template formatter (ChatML-style).
// /// Matches: <|im_start|>{role}\n{content}<|im_end|>\n
// /// Optional: tool list on the *system* line, and tool responses wrapped with
// /// <|tool_response_start|> ... <|tool_response_end|>.
// ///
// /// Reference template:
// /// https://huggingface.co/LiquidAI/LFM2-700M/blob/main/chat_template.jinja
// class Lfm2Format extends PromptFormat {
//   static const _imStart = '<|im_start|>';
//   static const _imEnd = '<|im_end|>\n';
//   static const _toolListStart = '<|tool_list_start|>';
//   static const _toolListEnd = '<|tool_list_end|>';
//   static const _toolRespStart = '<|tool_response_start|>';
//   static const _toolRespEnd = '<|tool_response_end|>';
//
//   /// If true, prefixes BOS the same way HF does in the template.
//   /// (Llama.cpp typically handles BOS internally; keep false unless needed.)
//   final bool includeBos;
//
//   Lfm2Format({this.includeBos = false})
//       : super(
//     // If you have a PromptFormatType.lfm2, use that; otherwise `chatml` fits.
//     PromptFormatType.chatml,
//     inputSequence: '$_imStartuser\n',
//     outputSequence: '$_imStartassistant\n',
//     systemSequence: '$_imStartsystem\n',
//     stopSequence: _imEnd,
//   );
//
//   /// One-shot helper for a single-turn prompt:
//   /// <|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant\n
//   String preparePrompt(String prompt) {
//     final bos = includeBos ? _bosToken() : '';
//     return '$bos$inputSequence$prompt$stopSequence$outputSequence';
//   }
//
//   /// Formats a chat according to the LFM2 template.
//   ///
//   /// messages: list of { "role": "system|user|assistant|tool", "content": String }
//   ///
//   /// tools (optional): a *JSON-serializable* description of available tools,
//   /// which will be appended to the system prompt like:
//   ///   "List of tools: <|tool_list_start|>[...json...]<|tool_list_end|>"
//   ///
//   /// addGenerationPrompt: if true, appends an open assistant turn at the end.
//   String formatMessagesLfm2(
//       List<Map<String, dynamic>> messages, {
//         Object? tools,
//         bool addGenerationPrompt = false,
//       }) {
//     final buf = StringBuffer();
//
//     if (includeBos) buf.write(_bosToken());
//
//     // Extract leading system message (if any), then append tools listing.
//     String? systemPrompt;
//     List<Map<String, dynamic>> rest = messages;
//     if (messages.isNotEmpty && messages.first['role'] == 'system') {
//       systemPrompt = messages.first['content']?.toString() ?? '';
//       rest = messages.sublist(1);
//     }
//     if (tools != null) {
//       final jsonTools = jsonEncode(tools);
//       final toolsLine =
//           'List of tools: $_toolListStart$jsonTools$_toolListEnd';
//       systemPrompt = (systemPrompt?.isNotEmpty ?? false)
//           ? '$systemPrompt\n$toolsLine'
//           : toolsLine;
//     }
//     if (systemPrompt != null && systemPrompt.isNotEmpty) {
//       buf.write('$systemSequence$systemPrompt$stopSequence');
//     }
//
//     // Emit remaining messages with tool-response wrapping when role == "tool".
//     for (final m in rest) {
//       final role = (m['role'] ?? '').toString();
//       var content = (m['content'] ?? '').toString();
//
//       if (role == 'tool') {
//         content = '$_toolRespStart$content$_toolRespEnd';
//       }
//
//       switch (role) {
//         case 'user':
//           buf.write('$inputSequence$content$stopSequence');
//           break;
//         case 'assistant':
//           buf.write('$outputSequence$content$stopSequence');
//           break;
//         case 'system':
//           buf.write('$systemSequence$content$stopSequence');
//           break;
//         case 'tool':
//         // Tool messages are represented as role "tool" blocks as per template.
//           buf.write('$_imStart$role\n$content$stopSequence');
//           break;
//         default:
//         // Fallback to user if unknown.
//           buf.write('$inputSequence$content$stopSequence');
//       }
//     }
//
//     if (addGenerationPrompt) {
//       buf.write(outputSequence); // open assistant turn
//     }
//
//     return buf.toString();
//   }
//
//   /// Base-class compatibility (no tools, no trailing assistant).
//   /// If you need tools or an open assistant turn, call formatMessagesLfm2.
//   @override
//   String formatMessages(List<Map<String, dynamic>> messages) {
//     return formatMessagesLfm2(messages, tools: null, addGenerationPrompt: false);
//   }
//
//   // You can leave filterResponse as inherited (works via SequenceFilter),
//   // since our sequences align with the template tokens.
//
//   String _bosToken() => '{{- bos_token -}}\n';
// }
