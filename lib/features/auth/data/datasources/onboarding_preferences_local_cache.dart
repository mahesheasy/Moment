import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed the first-run onboarding carousel.
class OnboardingPreferencesLocalCache {
  static const _completeKey = 'onboarding_complete_v1';

  bool? _complete;

  bool get isCompleteSync => _complete ?? false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _complete = prefs.getBool(_completeKey) ?? false;
  }

  Future<bool> isComplete() async {
    if (_complete != null) return _complete!;
    await load();
    return _complete ?? false;
  }

  Future<void> markComplete() async {
    _complete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completeKey, true);
  }
}
