import 'dart:typed_data';
import 'ai_model_interface.dart';

/// Manager class to handle multiple AI models
class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  final Map<String, AIModelInterface> _models = {};
  AIModelInterface? _activeModel;

  /// Register a new AI model
  void registerModel(AIModelInterface model) {
    _models['${model.platform}_${model.modelName}'] = model;
    
    // If this is the first model, make it the active one
    if (_activeModel == null) {
      _activeModel = model;
    }
  }

  /// Get a specific model by platform and model name
  AIModelInterface? getModel(String platform, String modelName) {
    return _models['${platform}_$modelName'];
  }

  /// Get all registered models
  List<AIModelInterface> get allModels => _models.values.toList();

  /// Get all available platforms
  List<String> get platforms => _models.values
      .map((model) => model.platform)
      .toSet()
      .toList();

  /// Get all models for a specific platform
  List<AIModelInterface> getModelsForPlatform(String platform) {
    return _models.values
        .where((model) => model.platform == platform)
        .toList();
  }

  /// Set the active model by platform and model name
  bool setActiveModel(String platform, String modelName) {
    final model = getModel(platform, modelName);
    if (model != null) {
      _activeModel = model;
      return true;
    }
    return false;
  }

  /// Get the currently active model
  AIModelInterface? get activeModel => _activeModel;

  /// Initialize all registered models
  Future<void> initializeAllModels() async {
    for (final model in _models.values) {
      await model.initialize();
    }
  }

  /// Analyze images using the active model
  Future<Map<String, dynamic>> analyzeImages(
    String prompt,
    List<Uint8List> imageBytesList,
    List<String?> mimeTypes,
  ) async {
    if (_activeModel == null) {
      throw Exception('No active model available');
    }
    return await _activeModel!.analyzeImages(prompt, imageBytesList, mimeTypes);
  }

  /// Generate text using the active model
  Future<Map<String, dynamic>> generateText(String prompt) async {
    if (_activeModel == null) {
      throw Exception('No active model available');
    }
    return await _activeModel!.generateText(prompt);
  }
}