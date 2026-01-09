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
  // You can set the image save directory here
  final GeminiService _geminiService = GeminiService(saveDirectory: '~/Pictures/ai');
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

    final  resultMap = await _geminiService.analyzeImages(prompt, _imageBytesList, mimeTypes);
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
              child: _imageBytesList.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageBytesList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            AppBar(
                                              title: Text('Image ${index + 1}'),
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
                                                minScale: 0.1,
                                                maxScale: 5.0,
                                                boundaryMargin: const EdgeInsets.all(double.infinity),
                                                child: Image.memory(
                                                  _imageBytesList[index],
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
                                    _imageBytesList[index],
                                    fit: BoxFit.cover,
                                    width: 280,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _images.removeAt(index);
                                        _imageBytesList.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No images selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(_imageBytesList.isEmpty ? 'Pick Images' : 'Add More Images (${_imageBytesList.length})'),
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
