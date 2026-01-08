import 'package:flutter/material.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onPickImages;
  final VoidCallback onAnalyzeImage;
  final bool isLoading;
  final int imageCount;

  const ActionButtonsWidget({
    super.key,
    required this.onPickImages,
    required this.onAnalyzeImage,
    required this.isLoading,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onPickImages,
          icon: const Icon(Icons.photo_library),
          label: Text(
            imageCount == 0 
              ? 'Pick Images' 
              : 'Add More Images ($imageCount)',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isLoading ? null : onAnalyzeImage,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: const Text('Ask AI'),
        ),
      ],
    );
  }
}