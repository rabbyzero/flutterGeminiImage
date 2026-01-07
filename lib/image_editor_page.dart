import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'gemini_service.dart';
import 'result_page.dart';

class ImageEditorPage extends StatefulWidget {
  const ImageEditorPage({super.key});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _promptController = TextEditingController();
  
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _image = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isLoading = true;
    });

    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      prompt = _imageBytes != null ? 'Describe this image details.' : 'Hello, who are you?';
    }

    String? mimeType;
    if (_imageBytes != null) {
      mimeType = _image?.mimeType;
      if (mimeType == null && _image != null) {
        mimeType = lookupMimeType(_image!.path);
      }
      // Fallback if lookup fails
      mimeType ??= 'image/jpeg';
    }

    final  resultMap = await _geminiService.analyzeImage(prompt, _imageBytes, mimeType);
    final resultText = resultMap['text'] as String?;
    final resultImage = resultMap['image'] as Uint8List?;
    
    print('Analysis result received: text=${resultText?.substring(0, (resultText.length > 20 ? 20 : resultText.length))}..., image=${resultImage?.length} bytes');

    if (!mounted) return;

    setState(() {
        _isLoading = false;
        if (resultText != null || resultImage != null) {
           _lastResult = {
             'text': resultText ?? '',
             'originalImage': _imageBytes,
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
            originalImageBytes: _lastResult!['originalImage'],
            generatedImageBytes: _lastResult!['generatedImage'],
            text: _lastResult!['text'],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                           showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AppBar(
                                      title: const Text('Original Image'),
                                      automaticallyImplyLeading: false,
                                      actions: [
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                    Flexible(
                                      child: InteractiveViewer(
                                        child: Image.memory(
                                          _imageBytes!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                        },
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Ask something about the image...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _analyzeImage,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    ) 
                  : const Icon(Icons.send),
              label: const Text('Ask Gemini'),
            ),
          ],
        ),
      ),
    );
  }
}
