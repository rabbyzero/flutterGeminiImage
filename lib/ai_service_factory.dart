import 'ai_service.dart';
import 'gemini_service.dart';

enum AIModelType {
  gemini,
}

class AIServiceFactory {
  static AIService createService(AIModelType type, {String? saveDirectory}) {
    switch (type) {
      case AIModelType.gemini:
        return GeminiService(saveDirectory: saveDirectory);
    }
  }
} // AIServiceFactory
