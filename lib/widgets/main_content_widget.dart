import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'generation_config_widget.dart';
import 'action_buttons_widget.dart';
import 'image_display_widget.dart';
import 'prompt_input_widget.dart';

class MainContentWidget extends StatelessWidget {
  final List<Uint8List> imageBytesList;
  final List<XFile> images;
  final bool isLoading;
  final int imageCount;
  final TextEditingController promptController;
  final VoidCallback onPickImages;
  final VoidCallback onAnalyzeImage;
  final Function(int) onImageTap;
  final Function(int) onRemoveImage;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;

  const MainContentWidget({
    super.key,
    required this.imageBytesList,
    required this.images,
    required this.isLoading,
    required this.imageCount,
    required this.promptController,
    required this.onPickImages,
    required this.onAnalyzeImage,
    required this.onImageTap,
    required this.onRemoveImage,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: ImageDisplayWidget(
            imageBytesList: imageBytesList,
            images: images,
            onImageTap: onImageTap,
            onRemoveImage: onRemoveImage,
          ),
        ),
        const SizedBox(height: 16),
        GenerationConfigWidget(onConfigChanged: onConfigChanged),
        const SizedBox(height: 16),
        ActionButtonsWidget(
          onPickImages: onPickImages,
          onAnalyzeImage: onAnalyzeImage,
          isLoading: isLoading,
          imageCount: imageCount,
        ),
        const SizedBox(height: 16),
        PromptInputWidget(
          controller: promptController,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}