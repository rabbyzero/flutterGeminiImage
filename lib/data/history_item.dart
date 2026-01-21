import 'dart:typed_data';

class HistoryItem {
  final String id;
  final DateTime timestamp;
  final String prompt;
  final List<Uint8List> originalImages;
  final String text;
  final Uint8List? generatedImage;
  final String? thought;
  final Map<String, dynamic>? usage;

  HistoryItem({
    required this.id,
    required this.timestamp,
    required this.prompt,
    required this.originalImages,
    required this.text,
    this.generatedImage,
    this.thought,
    this.usage,
  });
}
