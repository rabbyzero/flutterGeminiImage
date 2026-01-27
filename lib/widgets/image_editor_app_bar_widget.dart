import 'package:flutter/material.dart';
import '../services/model_manager.dart';
import 'model_selector_widget.dart';

class ImageEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ModelManager modelManager;
  final VoidCallback? onHistoryPressed;
  final VoidCallback? onModelChanged;

  const ImageEditorAppBar({
    super.key,
    required this.modelManager,
    this.onHistoryPressed,
    this.onModelChanged,
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
            onModelChanged?.call();
          },
        ),
        IconButton(
          onPressed: onHistoryPressed,
          icon: const Icon(Icons.history),
          tooltip: 'Show History',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}