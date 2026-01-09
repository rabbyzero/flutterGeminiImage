import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageListWidget extends StatelessWidget {
  final List<Uint8List>? originalImageBytesList;
  final Uint8List? generatedImageBytes;
  final Function(Uint8List imageBytes, String title) onImagePressed;

  const ImageListWidget({
    super.key,
    this.originalImageBytesList,
    this.generatedImageBytes,
    required this.onImagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (originalImageBytesList != null && originalImageBytesList!.isNotEmpty)
          ...List.generate(originalImageBytesList!.length, (index) {
            return ElevatedButton.icon(
              onPressed: () => onImagePressed(
                originalImageBytesList![index], 
                'Original Image ${index + 1}'
              ),
              icon: const Icon(Icons.image),
              label: Text('Original ${index + 1}'),
            );
          }),
        if (generatedImageBytes != null)
          ElevatedButton.icon(
            onPressed: () => onImagePressed(generatedImageBytes!, 'Generated Image'),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('View Generated'),
          ),
      ],
    );
  }
}