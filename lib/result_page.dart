import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'widgets/widgets.dart';

class ResultPage extends StatelessWidget {
  final List<Uint8List>? originalImageBytesList;
  final Uint8List? generatedImageBytes;
  final String text;
  final Map<String, dynamic>? usage;

  const ResultPage({
    super.key,
    this.originalImageBytesList,
    this.generatedImageBytes,
    required this.text,
    this.usage,
  });

  void _showImageDialog(BuildContext context, Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      builder: (context) => ImageDialogWidget(imageBytes: imageBytes, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Response'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageListWidget(
              originalImageBytesList: originalImageBytesList,
              generatedImageBytes: generatedImageBytes,
              onImagePressed: (imageBytes, title) => _showImageDialog(context, imageBytes, title),
            ),
            if ((originalImageBytesList != null && originalImageBytesList!.isNotEmpty) || generatedImageBytes != null)
              const SizedBox(height: 24),
            MarkdownDisplayWidget(text: text),
            if (usage != null) ...[
              const SizedBox(height: 24),
              TokenUsageDisplayWidget(usage: usage),
            ],
          ],
        ),
      ),
    );
  }
}