import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSelectionWidget extends StatelessWidget {
  final List<Uint8List> imageBytesList;
  final List<XFile> images;
  final Function(int index) onImageTap;
  final Function(int index) onRemoveImage;

  const ImageSelectionWidget({
    super.key,
    required this.imageBytesList,
    required this.images,
    required this.onImageTap,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageBytesList.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageBytesList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onImageTap(index),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: MemoryImage(imageBytesList[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}