import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the post-login permissions setup flow has been completed.
class SetupPreferencesLocalCache {
  static const _permissionsCompleteKey = 'setup_permissions_complete';

  bool? _permissionsComplete;

  bool get isPermissionsSetupCompleteSync => _permissionsComplete ?? false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _permissionsComplete = prefs.getBool(_permissionsCompleteKey) ?? false;
  }

  Future<bool> isPermissionsSetupComplete() async {
    if (_permissionsComplete != null) return _permissionsComplete!;
    await load();
    return _permissionsComplete ?? false;
  }

  Future<void> markPermissionsSetupComplete() async {
    _permissionsComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsCompleteKey, true);
  }
}
