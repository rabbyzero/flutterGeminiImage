import 'dart:typed_data';

/// Abstract interface for AI models from different platforms
abstract class AIModelInterface {
  /// The name of the AI model
  String get modelName;

  /// The platform the model belongs to (e.g., 'Gemini', 'OpenAI', 'Anthropic')
  String get platform;

  /// Initialize the AI model service
  Future<void> initialize();

  /// Analyze images with a text prompt
  Future<Map<String, dynamic>> analyzeImages(
    String prompt,
    List<Uint8List> imageBytesList,
    List<String?> mimeTypes,
  );

  /// Generate content based on text prompt only
  Future<Map<String, dynamic>> generateText(
    String prompt,
  );
}