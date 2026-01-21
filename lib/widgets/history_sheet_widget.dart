import 'package:flutter/material.dart';
import '../models/history_item.dart';
import 'history_item_widget.dart'; // Import the new HistoryItemWidget

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
                        return HistoryItemWidget(
                          item: item,
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