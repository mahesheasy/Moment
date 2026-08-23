import 'dart:async';

class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 250)});

  final Duration duration;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
