import 'package:moment/core/result/result.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

abstract class WidgetPreferencesRepository {
  Future<Result<WidgetPreferencesBundle>> getPreferences();

  Future<Result<WidgetPreferencesBundle>> savePreferences(
    WidgetPreferences preferences,
  );

  Future<Result<WidgetPreferencesBundle>> savePrivacy(
    WidgetPreferences preferences,
  );
}
