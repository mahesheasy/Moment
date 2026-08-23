import 'package:flutter/foundation.dart';

/// Signals the circles list to reload after mutations from detail routes.
class CirclesListRefresh {
  final _version = ValueNotifier(0);

  ValueListenable<int> get version => _version;

  void requestRefresh() => _version.value++;
}
