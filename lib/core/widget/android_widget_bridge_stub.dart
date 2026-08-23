import 'package:moment/features/moments/domain/entities/moment.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

class AndroidWidgetBridge {
  const AndroidWidgetBridge();

  Future<void> syncMoment({
    required Moment moment,
    required WidgetPreferences preferences,
    required String headerTitle,
    String headerEmoji = '',
  }) async {}

  Future<void> syncReceivedMoments({
    required List<Moment> moments,
    required WidgetPreferences preferences,
    required Map<String, String> headerTitles,
    String headerEmoji = '',
  }) async {}

  Future<void> syncPreferences(WidgetPreferences preferences) async {}

  Future<WidgetPreferences?> readLocalPreferences() async => null;

  Future<WidgetPreferences?> readPrivacy() => readLocalPreferences();

  Future<void> clear() async {}

  Future<bool> isPinSupported() async => false;

  Future<bool> requestPinToHomeScreen() async => false;
}
