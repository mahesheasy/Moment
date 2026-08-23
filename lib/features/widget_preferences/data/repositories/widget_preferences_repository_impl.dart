import 'package:moment/core/config/app_features.dart';
import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/widget_preferences/data/datasources/widget_preferences_remote_data_source.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';
import 'package:moment/features/widget_preferences/domain/repositories/widget_preferences_repository.dart';

class WidgetPreferencesRepositoryImpl implements WidgetPreferencesRepository {
  WidgetPreferencesRepositoryImpl(this._remote, this._userIdProvider);

  final WidgetPreferencesRemoteDataSource _remote;
  final String? Function() _userIdProvider;

  @override
  Future<Result<WidgetPreferencesBundle>> getPreferences() async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      final bundle = await _remote.getPreferences();
      return Success(_withDevThemes(bundle));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<WidgetPreferencesBundle>> savePreferences(
    WidgetPreferences preferences,
  ) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.savePreferences(preferences));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  @override
  Future<Result<WidgetPreferencesBundle>> savePrivacy(
    WidgetPreferences preferences,
  ) async {
    if (_userIdProvider() == null) return const Failed(AuthenticationFailure());

    try {
      return Success(await _remote.savePrivacy(preferences));
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }

  WidgetPreferencesBundle _withDevThemes(WidgetPreferencesBundle bundle) {
    if (!AppFeatures.momentPlusWidgetsUnlocked) return bundle;
    return WidgetPreferencesBundle(
      preferences: bundle.preferences,
      isPremium: bundle.isPremium,
      themes: WidgetTheme.relationshipThemes,
      typographyOptions: bundle.typographyOptions,
      widgetModes: bundle.widgetModes,
      savedPreferences: bundle.savedPreferences,
    );
  }
}
