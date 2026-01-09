import 'package:flutter/material.dart';

class AnalysisInputArea extends StatelessWidget {
  final VoidCallback onPickImages;
  final TextEditingController promptController;
  final VoidCallback? onAnalyze;
  final bool isLoading;
  final int imageCount;

  const AnalysisInputArea({
    super.key,
    required this.onPickImages,
    required this.promptController,
    required this.onAnalyze,
    required this.isLoading,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onPickImages,
          icon: const Icon(Icons.photo_library),
          label: Text(imageCount == 0 ? 'Pick Images' : 'Add More Images ($imageCount)'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: promptController,
          decoration: const InputDecoration(
            labelText: 'Prompt',
            hintText: 'Ask something about the image...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isLoading ? null : onAnalyze,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: const Text('Ask Gemini'),
        ),
      ],
    );
  }
}
