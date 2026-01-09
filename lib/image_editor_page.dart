import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'ai_service.dart';
import 'ai_service_factory.dart';
import 'result_page.dart';
import 'widgets/analysis_input_area.dart';
import 'widgets/image_preview_list.dart';

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  // You can set the image save directory here
  final AIService _aiService = AIServiceFactory.createService(AIModelType.gemini, saveDirectory: '~/Pictures/ai');
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptController = TextEditingController();
  
  List<XFile> _images = [];
  List<Uint8List> _imageBytesList = [];
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;

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

    final  resultMap = await _aiService.analyzeImages(prompt, _imageBytesList, mimeTypes);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePreviewList(
              imageBytesList: _imageBytesList,
              onRemove: (index) {
                setState(() {
                  _images.removeAt(index);
                  _imageBytesList.removeAt(index);
                });
              },
            ),
            const SizedBox(height: 16),
            AnalysisInputArea(
              onPickImages: _pickImages,
              promptController: _promptController,
              onAnalyze: _isLoading ? null : _analyzeImage,
              isLoading: _isLoading,
              imageCount: _imageBytesList.length,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('AI Image Assistant'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        if (_lastResult != null)
          IconButton(
            onPressed: _navigateToResult,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Show Last Result',
          ),
      ],
    );
  }




}