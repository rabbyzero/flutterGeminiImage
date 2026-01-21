import 'package:flutter/material.dart';
import '../models/history_item.dart';

class HistoryItemWidget extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const HistoryItemWidget({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildItemImageSection(context),
      title: Text(
        item.prompt.isNotEmpty ? item.prompt : 'Image Analysis',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: _buildSubtitle(context),
      onTap: onTap,
    );
  }

  Widget _buildItemImageSection(BuildContext context) {
    // If no original images and no generated image, show a text icon
    if (item.originalImages.isEmpty && item.generatedImages.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.title, size: 24),
      );
    }

    Widget? originalPart;
    if (item.originalImages.isNotEmpty) {
      originalPart = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          item.originalImages.first,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }

    Widget? generatedPart;
    if (item.generatedImages.isNotEmpty) {
      generatedPart = SizedBox(
        height: 50,
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: item.generatedImages.length > 3 ? 3 : item.generatedImages.length,
          separatorBuilder: (context, index) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
             return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                item.generatedImages[index],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );
    }

    if (originalPart != null && generatedPart != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          originalPart,
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          generatedPart,
        ],
      );
    }

    return originalPart ?? generatedPart!;
  }

  Widget _buildSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.text.replaceAll('\n', ' '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
             if (item.generatedImages.isNotEmpty)
                Container(
                   margin: const EdgeInsets.only(right: 8),
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                   ),
                   child: Text(
                      '${item.generatedImages.length} image${item.generatedImages.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer
                      ),
                   ),
                ),
            Text(
              item.timestamp.toString().substring(0, 16),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}