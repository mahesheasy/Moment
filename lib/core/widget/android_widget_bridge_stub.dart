import 'package:moment/core/widget/widget_background_reliability.dart';
import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

class AndroidWidgetBridge {
  const AndroidWidgetBridge();

  Future<void> syncMoment({
    required Moment moment,
    required WidgetPreferences preferences,
    required String headerTitle,
    String headerEmoji = '',
    bool isUnread = true,
    int syncGeneration = 0,
  }) async {}

  Future<void> syncMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
    bool showLatest = false,
    Map<String, bool>? isUnreadByMomentId,
    int syncGeneration = 0,
  }) async {}

  Future<void> syncReceivedMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
    bool showLatest = false,
    Map<String, bool>? isUnreadByMomentId,
    int syncGeneration = 0,
  }) async {}

  Future<void> syncPreferences(
    WidgetPreferences preferences, {
    int streakCount = 0,
  }) async {}

  Future<WidgetPreferences?> readLocalPreferences() async => null;

  Future<WidgetPreferences?> readPrivacy() => readLocalPreferences();

  Future<void> clear() async {}

  Future<void> markMomentViewedOnDevice(String momentId) async {}

  Future<bool> isPinSupported() async => false;

  Future<bool> requestPinToHomeScreen() async => false;

  Future<void> pushIncomingMoment({
    required Moment moment,
    required String headerTitle,
  }) async {}

  Future<void> saveWidgetSyncSession({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String userId,
    required String accessToken,
    String? refreshToken,
  }) async {}

  Future<void> clearWidgetSyncSession() async {}

  Future<WidgetBackgroundReliabilityStatus?> getBackgroundReliability() async =>
      null;

  Future<void> requestBatteryOptimizationExemption() async {}

  Future<void> openAutostartSettings() async {}
}
