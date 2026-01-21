import 'package:flutter/material.dart';
import '../data/history_item.dart';

class HistorySheetWidget extends StatelessWidget {
  final List<HistoryItem> history;
  final Function(HistoryItem) onItemSelected;

  const HistorySheetWidget({
    super.key,
    required this.history,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: const Text('History'),
              leading: const Icon(Icons.history),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('No history yet'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text request icon or Original Image
                              if (item.originalImages.isEmpty)
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.title),
                                )
                              else
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.memory(
                                    item.originalImages.first,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                              if (item.generatedImage != null) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward,
                                    size: 16, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.memory(
                                    item.generatedImage!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          title: Text(
                            item.prompt.isNotEmpty ? item.prompt : 'Image Analysis',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.text.replaceAll('\n', ' '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.timestamp.toString().substring(0, 16),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => onItemSelected(item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}