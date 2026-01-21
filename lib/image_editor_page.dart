import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'services/services.dart';
import 'models/history_item.dart';
import 'widgets/widgets.dart';
import 'result_page.dart';

class ImageEditorPage extends StatefulWidget {
  final List<Uint8List>? initialImageBytes;
  final List<HistoryItem>? initialHistory;

  const ImageEditorPage({
    super.key,
    this.initialImageBytes,
    this.initialHistory,
  });

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
  final List<HistoryItem> _history = [];
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;
  Map<String, dynamic> _generationConfig = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
     if (widget.initialHistory != null) {
      _history.addAll(widget.initialHistory!);
    }
    if (widget.initialImageBytes != null) {
      _imageBytesList.addAll(widget.initialImageBytes!);
      for (var bytes in widget.initialImageBytes!) {
        final mimeType = lookupMimeType('', headerBytes: bytes) ?? 'image/jpeg';
         _images.add(XFile.fromData(bytes, mimeType: mimeType));
      }
    }
  }

  Future<void> _initializeServices() async {
    // Register the Gemini 2.5 Flash service
    final geminiFlash = GeminiService(
      saveDirectory: '~/Pictures/ai',
      modelId: 'gemini-2.5-flash-image',
      displayName: 'Gemini 2.5 Flash',
    );
    _modelManager.registerModel(geminiFlash);

    // Register the Gemini 3 Pro service
    final geminiPro = GeminiService(
      saveDirectory: '~/Pictures/ai',
      modelId: 'gemini-3-pro-image-preview', // User provided model ID
      displayName: 'Gemini 3 Pro Preview',
    );
    _modelManager.registerModel(geminiPro);
    
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

  Future<void> _saveProxyConfig(String proxy) async {
    try {
      final file = File('assets/proxy.txt');
      String content = '';
      if (await file.exists()) {
        content = await file.readAsString();
      }
      
      final lines = content.split('\n');
      final newLines = <String>[];
      bool updated = false;
      bool foundExisting = false;

      for (var line in lines) {
        if (line.trim().startsWith('#') || line.trim().isEmpty) {
           newLines.add(line);
        } else {
          if (!foundExisting) {
            String currentProxy = line.trim();
            if (currentProxy != proxy) {
              newLines.add(proxy);
              updated = true;
            } else {
              newLines.add(line);
            }
            foundExisting = true;
          }
        }
      }

      if (!foundExisting) {
        newLines.add(proxy);
        updated = true;
      }

      if (updated) {
        await file.writeAsString(newLines.join('\n'));
      }
    } catch (e) {
      // Ignore
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
    
    // Save proxy if present in config
    if (_generationConfig.containsKey('proxy')) {
      await _saveProxyConfig(_generationConfig['proxy'] as String);
    }

    List<String?> mimeTypes = [];
    for (var i = 0; i < _images.length; i++) {
      String? mimeType = _images[i].mimeType;
      mimeType ??= lookupMimeType(_images[i].path);
      mimeType ??= 'image/jpeg';
      mimeTypes.add(mimeType);
    }

    final resultMap = await _modelManager.analyzeImages(
      prompt, 
      _imageBytesList, 
      mimeTypes,
      config: _generationConfig.isNotEmpty ? _generationConfig : null,
    );

    if (resultMap.containsKey('error') && resultMap['error'] != null) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ErrorSnackbar.showError(context, message: resultMap['error']);
      return;
    }

    final resultText = resultMap['text'] as String?;
    final resultImages = (resultMap['images'] as List<dynamic>?)?.cast<Uint8List>() ?? <Uint8List>[];
    if (resultImages.isEmpty) {
      // Production code shouldn't use print statements
      // for(var k in resultMap.keys) {
      //   print('$k ${resultMap[k]}');
      // }
    }


    // Production code shouldn't use print statements
    // print('Analysis result received: text=${resultText?.substring(0, (resultText.length > 20 ? 20 : resultText.length))}..., images=${resultImages.length}');

    if (!mounted) return;

    setState(() {
        _isLoading = false;
        if (resultText != null || resultImages.isNotEmpty) {
           _lastResult = {
             'text': resultText ?? '',
             'originalImages': _imageBytesList,
             'generatedImages': resultImages,
             'usage': resultMap['usage'],
             'thought': resultMap['thought'],
           };

           // Add to history
           _history.insert(0, HistoryItem(
             id: DateTime.now().millisecondsSinceEpoch.toString(),
             timestamp: DateTime.now(),
             prompt: prompt,
             originalImages: List.from(_imageBytesList),
             text: resultText ?? '',
             generatedImages: resultImages,
             thought: resultMap['thought'],
             usage: resultMap['usage'],
           ));
        }
    });

    if (_lastResult != null) {
      // Production code shouldn't use print statements
      // print('Navigating to ResultPage');
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    if (_lastResult == null) return;
    Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultPage(
            originalImageBytesList: _lastResult!['originalImages'],
            generatedImageBytesList: _lastResult!['generatedImages'],
            text: _lastResult!['text'],
            usage: _lastResult!['usage'],
            thought: _lastResult!['thought'],
            history: _history,
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
        onUseImage: () {
          Navigator.pop(context);
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageEditorPage(
                initialImageBytes: [_imageBytesList[index]],
                initialHistory: _history,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => HistorySheet(
        history: _history,
        onItemSelected: (item) {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultPage(
                originalImageBytesList: item.originalImages,
                generatedImageBytesList: item.generatedImages,
                text: item.text,
                usage: item.usage,
                thought: item.thought,
                history: _history,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ImageEditorAppBar(
        modelManager: _modelManager,
        onHistoryPressed: _showHistory,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: MainContentWidget(
          imageBytesList: _imageBytesList,
          images: _images,
          isLoading: _isLoading,
          imageCount: _imageBytesList.length,
          promptController: _promptController,
          onPickImages: _pickImages,
          onAnalyzeImage: _analyzeImage,
          onImageTap: _showImageDialog,
          onRemoveImage: (int index) {
            setState(() {
              _images.removeAt(index);
              _imageBytesList.removeAt(index);
            });
          },
          onConfigChanged: (config) {
            setState(() {
              _generationConfig = config;
            });
          },
        ),
      ),
    );
  }
}