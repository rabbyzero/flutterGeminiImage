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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (originalImageBytesList != null && originalImageBytesList!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Original Images (${originalImageBytesList!.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: originalImageBytesList!.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onImagePressed(
                    originalImageBytesList![index],
                    'Original Image ${index + 1}',
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        originalImageBytesList![index],
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (generatedImageBytes != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Generated Image',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          GestureDetector(
            onTap: () => onImagePressed(generatedImageBytes!, 'Generated Image'),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  generatedImageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}