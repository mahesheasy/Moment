import 'package:moment/core/logging/app_logger.dart';

abstract class FirebaseBootstrap {
  Future<void> initialize();
}

/// Firebase is wired in Version 0.7 (FCM). This no-op keeps Android/iOS
/// builds free of google-services until that version.
class NoOpFirebaseBootstrap implements FirebaseBootstrap {
  const NoOpFirebaseBootstrap({required this.logger});

  final AppLogger logger;

  @override
  Future<void> initialize() async {
    logger.info(
      'Firebase bootstrap skipped — not configured until Version 0.7.',
    );
  }
}
