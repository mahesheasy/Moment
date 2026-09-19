import 'package:flutter_test/flutter_test.dart';
import 'package:moment/features/widget_preferences/domain/entities/widget_preferences.dart';

void main() {
  test('WidgetPreferences defaults use minimal theme and latest mode', () {
    final prefs = WidgetPreferences.defaults();

    expect(prefs.theme, WidgetTheme.minimal);
    expect(prefs.widgetMode, WidgetMode.latest);
    expect(prefs.accentColor, WidgetPreferences.defaultAccent);
    expect(prefs.typography, WidgetTypography.defaultStyle);
  });

  test('WidgetPreferences fromJson parses remote payload', () {
    final prefs = WidgetPreferences.fromJson({
      'theme': 'sunset',
      'accent_color': '#FFB86C',
      'typography': 'serif',
      'widget_mode': 'person',
      'selected_person_id': 'abc-123',
    });

    expect(prefs.theme, WidgetTheme.sunset);
    expect(prefs.accentColor, '#FFB86C');
    expect(prefs.typography, WidgetTypography.serif);
    expect(prefs.widgetMode, WidgetMode.person);
    expect(prefs.selectedPersonId, 'abc-123');
  });

  test('WidgetPreferences toUpsertJson clears circle for person mode', () {
    const prefs = WidgetPreferences(
      theme: WidgetTheme.glass,
      accentColor: '#7EB6FF',
      typography: WidgetTypography.rounded,
      widgetMode: WidgetMode.person,
      selectedPersonId: 'friend-id',
      selectedCircleId: 'ignored',
    );

    final payload = prefs.toUpsertJson();

    expect(payload['p_theme'], 'glass');
    expect(payload['p_selected_person_id'], 'friend-id');
    expect(payload['p_selected_circle_id'], isNull);
  });

  test('WidgetPreferences fromJson reads privacy fields', () {
    final prefs = WidgetPreferences.fromJson({
      'theme': 'minimal',
      'privacy_mode': 'blur',
      'show_sender': false,
      'show_timestamp': true,
      'show_captions': true,
      'lock_screen_privacy': false,
      'paused': true,
    });

    expect(prefs.privacyMode, WidgetPrivacyMode.blur);
    expect(prefs.showSender, isFalse);
    expect(prefs.showCaptions, isTrue);
    expect(prefs.lockScreenPrivacy, isFalse);
    expect(prefs.paused, isTrue);
    expect(prefs.toPrivacyJson()['p_privacy_mode'], 'blur');
  });

  test('WidgetPreferences privacyForSender respects per-person scope', () {
    const prefs = WidgetPreferences(
      theme: WidgetTheme.minimal,
      accentColor: '#FF6B8A',
      typography: WidgetTypography.defaultStyle,
      widgetMode: WidgetMode.latest,
      privacyMode: WidgetPrivacyMode.private,
      privacyPersonId: 'friend-1',
    );

    expect(prefs.privacyForSender('friend-1'), WidgetPrivacyMode.private);
    expect(prefs.privacyForSender('other'), WidgetPrivacyMode.full);
  });

  test('WidgetPreferences privacyForSender prefers per-sender overrides', () {
    const prefs = WidgetPreferences(
      theme: WidgetTheme.minimal,
      accentColor: '#FF6B8A',
      typography: WidgetTypography.defaultStyle,
      widgetMode: WidgetMode.latest,
      privacyMode: WidgetPrivacyMode.full,
      privacyOverrides: {'friend-1': WidgetPrivacyMode.blur},
    );

    expect(prefs.privacyForSender('friend-1'), WidgetPrivacyMode.blur);
    expect(prefs.privacyForSender('friend-2'), WidgetPrivacyMode.full);
  });

  test('WidgetPreferences fromJson reads privacy overrides', () {
    final prefs = WidgetPreferences.fromJson({
      'theme': 'minimal',
      'privacy_mode': 'full',
      'privacy_overrides': {'friend-1': 'blur', 'friend-2': 'private'},
    });

    expect(prefs.privacyOverrides['friend-1'], WidgetPrivacyMode.blur);
    expect(prefs.privacyOverrides['friend-2'], WidgetPrivacyMode.private);
    expect(
      prefs.toPrivacyJson()['p_privacy_overrides'],
      {'friend-1': 'blur', 'friend-2': 'private'},
    );
  });

  test('WidgetTheme relationship themes focus on people', () {
    expect(WidgetTheme.relationshipThemes, [
      WidgetTheme.love,
      WidgetTheme.family,
      WidgetTheme.friends,
      WidgetTheme.bestie,
      WidgetTheme.minimal,
    ]);
    expect(WidgetTheme.family.label, 'Family');
    expect(WidgetTheme.bestie.emoji, '✨');
    expect(WidgetTheme.love.defaultAccent, '#FF6B8A');
  });

  test('WidgetPreferences toJson round-trips through fromJson', () {
    const prefs = WidgetPreferences(
      theme: WidgetTheme.sunset,
      accentColor: '#FFB86C',
      typography: WidgetTypography.mono,
      widgetMode: WidgetMode.latest,
      showCaptions: true,
    );

    final restored = WidgetPreferences.fromJson(prefs.toJson());

    expect(restored, prefs);
  });

  test('privacyForSender default falls back to global mode', () {
    const prefs = WidgetPreferences(
      theme: WidgetTheme.minimal,
      accentColor: '#FF6B8A',
      typography: WidgetTypography.defaultStyle,
      widgetMode: WidgetMode.latest,
      privacyMode: WidgetPrivacyMode.blur,
    );

    expect(prefs.privacyForSender('any-friend'), WidgetPrivacyMode.blur);
  });

  test('privacyForSender per-person override beats global', () {
    const prefs = WidgetPreferences(
      theme: WidgetTheme.minimal,
      accentColor: '#FF6B8A',
      typography: WidgetTypography.defaultStyle,
      widgetMode: WidgetMode.latest,
      privacyMode: WidgetPrivacyMode.blur,
      privacyOverrides: {
        'mom-id': WidgetPrivacyMode.private,
        'jay-id': WidgetPrivacyMode.full,
      },
    );

    expect(prefs.privacyForSender('mom-id'), WidgetPrivacyMode.private);
    expect(prefs.privacyForSender('jay-id'), WidgetPrivacyMode.full);
    expect(prefs.privacyForSender('other'), WidgetPrivacyMode.blur);
  });

  test('WidgetPreferences mergeLocal applies device overrides', () {
    const remote = WidgetPreferences(
      theme: WidgetTheme.minimal,
      accentColor: '#C4A484',
      typography: WidgetTypography.defaultStyle,
      widgetMode: WidgetMode.latest,
    );
    const local = WidgetPreferences(
      theme: WidgetTheme.love,
      accentColor: '#FF4D7D',
      typography: WidgetTypography.serif,
      widgetMode: WidgetMode.latest,
      showCaptions: true,
    );

    final merged = remote.mergeLocal(local);

    expect(merged.theme, WidgetTheme.love);
    expect(merged.accentColor, '#FF4D7D');
    expect(merged.typography, WidgetTypography.serif);
    expect(merged.showCaptions, isTrue);
  });
}
