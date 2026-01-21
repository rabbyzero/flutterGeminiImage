import 'package:flutter/material.dart';
import '../models/history_item.dart';
import 'history_sheet_widget.dart';

/// Re-exporting the HistorySheetWidget for backward compatibility
export 'history_sheet_widget.dart' show HistorySheetWidget;

/// @Deprecated('Use HistorySheetWidget instead')
typedef HistorySheet = HistorySheetWidget;
