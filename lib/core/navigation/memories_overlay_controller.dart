import 'package:flutter/foundation.dart';

/// Controls the full-screen Memories overlay opened by swiping up on Home.
class MemoriesOverlayController extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void toggle() {
    if (_isOpen) {
      close();
    } else {
      open();
    }
  }
}
