import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models/history_item.dart';
import 'widgets/widgets.dart';
import 'image_editor_page.dart';

class ResultPage extends StatelessWidget {
  final List<Uint8List>? originalImageBytesList;
  final List<Uint8List>? generatedImageBytesList;
  final String text;
  final String? thought;
  final Map<String, dynamic>? usage;
  final List<HistoryItem> history; // Add history parameter
  final String? curl;

  const ResultPage({
    super.key,
    this.originalImageBytesList,
    this.generatedImageBytesList,
    required this.text,
    this.thought,
    this.usage,
    this.history = const [], // Default to empty list
    this.curl,
  });

  void _showImageDialog(BuildContext context, Uint8List imageBytes, String title) {
    showDialog(
      context: context,
      builder: (context) => ImageDialogWidget(
        imageBytes: imageBytes, 
        title: title,
        onUseImage: () {
          Navigator.pop(context); // Close dialog
          // Navigate to new editor page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageEditorPage(
                initialImageBytes: [imageBytes],
                initialHistory: history,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => HistorySheet(
        history: history,
        onItemSelected: (item) {
          Navigator.pop(context); // Close sheet
          // Navigate to new result page (replace current one)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultPage(
                originalImageBytesList: item.originalImages,
                generatedImageBytesList: item.generatedImages,
                text: item.text,
                usage: item.usage,
                thought: item.thought,
                history: history, // Pass history along
                curl: item.curl,
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
      appBar: AppBar(
        title: const Text('Gemini Response'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
           IconButton(
            onPressed: () => _showHistory(context),
            icon: const Icon(Icons.history),
            tooltip: 'Show History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageListWidget(
              originalImageBytesList: originalImageBytesList,
              generatedImageBytesList: generatedImageBytesList,
              onImagePressed: (imageBytes, title) => _showImageDialog(context, imageBytes, title),
            ),
            if ((originalImageBytesList != null && originalImageBytesList!.isNotEmpty) || (generatedImageBytesList != null && generatedImageBytesList!.isNotEmpty))
              const SizedBox(height: 24),
            
            if (thought != null && thought!.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: ExpansionTile(
                  leading: const Icon(Icons.psychology),
                  title: const Text('Thinking Process'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MarkdownDisplayWidget(text: thought!),
                    ),
                  ],
                ),
              ),
            ],

            MarkdownDisplayWidget(text: text),
            if (usage != null) ...[
              const SizedBox(height: 24),
              TokenUsageDisplayWidget(usage: usage),
            ],
            
            if (curl != null && curl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: ExpansionTile(
                  leading: const Icon(Icons.code),
                  title: const Text('CURL Command'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        curl!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}