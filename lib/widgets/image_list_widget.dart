import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageListWidget extends StatelessWidget {
  final List<Uint8List>? originalImageBytesList;
  final List<Uint8List>? generatedImageBytesList;
  final Function(Uint8List imageBytes, String title) onImagePressed;

  const ImageListWidget({
    super.key,
    this.originalImageBytesList,
    this.generatedImageBytesList,
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
        if (generatedImageBytesList != null && generatedImageBytesList!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Generated Images (${generatedImageBytesList!.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: generatedImageBytesList!.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onImagePressed(
                    generatedImageBytesList![index],
                    'Generated Image ${index + 1}',
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        generatedImageBytesList![index],
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
        ],
      ],
    );
  }
}