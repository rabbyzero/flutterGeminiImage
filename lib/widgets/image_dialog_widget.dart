import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageDialogWidget extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;
  final VoidCallback? onUseImage;

  const ImageDialogWidget({
    super.key,
    required this.imageBytes,
    this.title = 'Image Preview',
    this.onUseImage,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBar(
            title: Text(title),
            automaticallyImplyLeading: false,
            actions: [
              if (onUseImage != null)
                TextButton.icon(
                  onPressed: onUseImage,
                  icon: const Icon(Icons.edit),
                  label: const Text('Use Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
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
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}