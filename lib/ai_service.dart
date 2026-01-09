import 'dart:typed_data';

abstract class AIService {
  Future<Map<String, dynamic>> analyzeImages(String prompt, List<Uint8List> imageBytesList, List<String?> mimeTypes);
}
