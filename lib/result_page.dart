import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ResultPage extends StatelessWidget {
  final List<Uint8List>? originalImageBytesList;
  final Uint8List? generatedImageBytes;
  final String text;

  const ResultPage({
    super.key,
    this.originalImageBytesList,
    this.generatedImageBytes,
    required this.text,
  });

  void _showImageDialog(BuildContext context, Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(title),
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
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (originalImageBytesList != null && originalImageBytesList!.isNotEmpty)
                  ...List.generate(originalImageBytesList!.length, (index) {
                    return ElevatedButton.icon(
                      onPressed: () => _showImageDialog(
                        context, 
                        originalImageBytesList![index], 
                        'Original Image ${index + 1}'
                      ),
                      icon: const Icon(Icons.image),
                      label: Text('Original ${index + 1}'),
                    );
                  }),
                if (generatedImageBytes != null)
                   ElevatedButton.icon(
                    onPressed: () => _showImageDialog(context, generatedImageBytes!, 'Generated Image'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('View Generated'),
                  ),
              ],
            ),
            if ((originalImageBytesList != null && originalImageBytesList!.isNotEmpty) || generatedImageBytes != null)
              const SizedBox(height: 24),
            const Text(
              'Detailed Analysis:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: MarkdownBody(
                data: text,
                selectable: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
