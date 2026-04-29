import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  static const List<String> trackedSymbols = ['AAPL', 'TSLA', 'NVDA', 'MSFT'];

  String _selectedTicker = trackedSymbols.first;

  String get selectedTicker => _selectedTicker;

  void selectTicker(String ticker) {
    final normalizedTicker = ticker.toUpperCase();
    if (_selectedTicker == normalizedTicker) {
      return;
    }
    _selectedTicker = normalizedTicker;
    notifyListeners();
  }
}
