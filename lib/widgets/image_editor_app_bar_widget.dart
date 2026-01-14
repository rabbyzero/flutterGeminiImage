import 'package:flutter/material.dart';
import '../models/model_manager.dart';
import 'model_selector_widget.dart';

class ImageEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ModelManager modelManager;
  final VoidCallback? navigateToResult;
  final bool hasLastResult;

  const ImageEditorAppBar({
    super.key,
    required this.modelManager,
    this.navigateToResult,
    this.hasLastResult = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('AI Image Assistant'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        ModelSelectorWidget(
          modelManager: modelManager,
          onModelSelected: (String platform, String model) {
            modelManager.setActiveModel(platform, model);
          },
        ),
        if (hasLastResult)
          IconButton(
            onPressed: navigateToResult,
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Show Last Result',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}