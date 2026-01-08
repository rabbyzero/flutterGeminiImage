import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'models/model_manager.dart';
import 'models/gemini_service.dart';
import 'models/openai_service.dart';
import 'widgets/image_display_widget.dart';
import 'widgets/prompt_input_widget.dart';
import 'widgets/action_buttons_widget.dart';
import 'widgets/image_dialog_widget.dart';
import 'result_page.dart';

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  // Initialize the model manager and register services
  final ModelManager _modelManager = ModelManager();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptController = TextEditingController();
  
  List<XFile> _images = [];
  List<Uint8List> _imageBytesList = [];
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Register the Gemini service
    final geminiService = GeminiService(saveDirectory: '~/Pictures/ai');
    _modelManager.registerModel(geminiService);
    
    // Register the OpenAI service
    final openAIService = OpenAIService(saveDirectory: '~/Pictures/ai');
    _modelManager.registerModel(openAIService);
    
    // Here you can register more services from other AI platforms
    // final anthropicService = AnthropicService(saveDirectory: '~/Pictures/ai');
    // _modelManager.registerModel(anthropicService);
    
    // Initialize all registered models
    await _modelManager.initializeAllModels();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final List<Uint8List> bytesList = [];
      for (var image in images) {
        final bytes = await image.readAsBytes();
        bytesList.add(bytes);
      }
      setState(() {
        _images = images;
        _imageBytesList = bytesList;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_modelManager.activeModel == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No active model available')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      prompt = _imageBytesList.isNotEmpty ? 'Describe these images in detail.' : 'Hello, who are you?';
    }

    List<String?> mimeTypes = [];
    for (var i = 0; i < _images.length; i++) {
      String? mimeType = _images[i].mimeType;
      if (mimeType == null) {
        mimeType = lookupMimeType(_images[i].path);
      }
      mimeType ??= 'image/jpeg';
      mimeTypes.add(mimeType);
    }

    final resultMap = await _modelManager.analyzeImages(prompt, _imageBytesList, mimeTypes);
    final resultText = resultMap['text'] as String?;
    final resultImage = resultMap['image'] as Uint8List?;
    
    print('Analysis result received: text=${resultText?.substring(0, (resultText.length > 20 ? 20 : resultText.length))}..., image=${resultImage?.length} bytes');

    if (!mounted) return;

    setState(() {
        _isLoading = false;
        if (resultText != null || resultImage != null) {
           _lastResult = {
             'text': resultText ?? '',
             'originalImages': _imageBytesList,
             'generatedImage': resultImage
           };
        }
    });

    if (_lastResult != null) {
      print('Navigating to ResultPage');
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    if (_lastResult == null) return;
    Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultPage(
            originalImageBytesList: _lastResult!['originalImages'],
            generatedImageBytes: _lastResult!['generatedImage'],
            text: _lastResult!['text'],
          ),
        ),
      );
  }

  void _showImageDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => ImageDialogWidget(
        imageBytes: _imageBytesList[index],
        title: 'Image ${index + 1}',
      ),
    );
  }

  // Method to build the model selection dropdown
  PopupMenuButton<String> _buildModelSelector() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.model_training),
      tooltip: 'Select AI Model',
      onSelected: (String modelKey) {
        final parts = modelKey.split('_');
        if (parts.length >= 2) {
          final platform = parts[0];
          final model = parts.sublist(1).join('_');
          _modelManager.setActiveModel(platform, model);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Active model: ${_modelManager.activeModel?.platform} ${_modelManager.activeModel?.modelName}')),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return _modelManager.allModels.map((model) {
          final modelKey = '${model.platform}_${model.modelName}';
          final isSelected = _modelManager.activeModel == model;
          return CheckedPopupMenuItem<String>(
            value: modelKey,
            checked: isSelected,
            child: Text('${model.platform} - ${model.modelName}'),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          _buildModelSelector(),
          if (_lastResult != null)
            IconButton(
              onPressed: _navigateToResult,
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Show Last Result',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ImageDisplayWidget(
                imageBytesList: _imageBytesList,
                images: _images,
                onImageTap: _showImageDialog,
                onRemoveImage: (int index) {
                  setState(() {
                    _images.removeAt(index);
                    _imageBytesList.removeAt(index);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            ActionButtonsWidget(
              onPickImages: _pickImages,
              onAnalyzeImage: _analyzeImage,
              isLoading: _isLoading,
              imageCount: _imageBytesList.length,
            ),
            const SizedBox(height: 16),
            PromptInputWidget(
              controller: _promptController,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}