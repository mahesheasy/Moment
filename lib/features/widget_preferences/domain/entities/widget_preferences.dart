import 'package:equatable/equatable.dart';
import 'package:moment/core/theme/widget_theme_palette.dart';

enum WidgetTheme {
  minimal,
  love,
  family,
  friends,
  bestie,
  glass,
  film,
  polaroid,
  midnight,
  sunset,
  retro,
  memory;

  /// Relationship-focused themes shown in the home widget picker.
  static const relationshipThemes = [
    WidgetTheme.love,
    WidgetTheme.family,
    WidgetTheme.friends,
    WidgetTheme.bestie,
    WidgetTheme.minimal,
  ];

  String get label => WidgetThemePalette.forTheme(this).label;

  String get emoji => WidgetThemePalette.forTheme(this).emoji;

  String get defaultAccent => WidgetThemePalette.forTheme(this).defaultAccent;

  String get concept => switch (this) {
    WidgetTheme.love => 'Romantic moments with someone special',
    WidgetTheme.family => 'Warm tones for your inner circle',
    WidgetTheme.friends => 'Fun, fresh energy with your crew',
    WidgetTheme.bestie => 'Golden vibes for your ride-or-die',
    WidgetTheme.minimal => 'Clean and timeless',
    WidgetTheme.glass => 'Frosted modern glass',
    WidgetTheme.film => 'Vintage film strip feel',
    WidgetTheme.polaroid => 'Instant camera nostalgia',
    WidgetTheme.midnight => 'Deep night sky mood',
    WidgetTheme.sunset => 'Golden hour warmth',
    WidgetTheme.retro => 'Throwback aesthetic',
    WidgetTheme.memory => 'On this day memories',
  };

  static WidgetTheme fromValue(String value) {
    return WidgetTheme.values.firstWhere(
      (theme) => theme.name == value,
      orElse: () => WidgetTheme.minimal,
    );
  }
}

enum WidgetTypography {
  defaultStyle,
  serif,
  rounded,
  mono;

  String get wireValue => switch (this) {
    WidgetTypography.defaultStyle => 'default',
    WidgetTypography.serif => 'serif',
    WidgetTypography.rounded => 'rounded',
    WidgetTypography.mono => 'mono',
  };

  String get label => switch (this) {
    WidgetTypography.defaultStyle => 'Poppins',
    WidgetTypography.serif => 'Serif',
    WidgetTypography.rounded => 'Rounded',
    WidgetTypography.mono => 'Mono',
  };

  String get subtitle => switch (this) {
    WidgetTypography.defaultStyle => 'Clean and modern',
    WidgetTypography.serif => 'Classic editorial',
    WidgetTypography.rounded => 'Soft and bold',
    WidgetTypography.mono => 'Minimal technical',
  };

  static WidgetTypography fromValue(String value) {
    return switch (value) {
      'serif' => WidgetTypography.serif,
      'rounded' => WidgetTypography.rounded,
      'mono' => WidgetTypography.mono,
      _ => WidgetTypography.defaultStyle,
    };
  }
}

enum WidgetMode {
  latest,
  person,
  circle;

  String get label => switch (this) {
    WidgetMode.latest => 'Latest moment',
    WidgetMode.person => 'From one person',
    WidgetMode.circle => 'From a circle',
  };

  static WidgetMode fromValue(String value) {
    return WidgetMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WidgetMode.latest,
    );
  }
}

/// Content density for the home-screen widget (text + overlay scale).
enum WidgetDisplaySize {
  large,
  medium,
  small;

  String get wireValue => name;

  String get label => switch (this) {
    WidgetDisplaySize.large => 'Large',
    WidgetDisplaySize.medium => 'Medium',
    WidgetDisplaySize.small => 'Small',
  };

  String get hint => switch (this) {
    WidgetDisplaySize.large => 'Best for details',
    WidgetDisplaySize.medium => 'Balanced',
    WidgetDisplaySize.small => 'Compact',
  };

  static WidgetDisplaySize fromValue(String? value) {
    return switch (value) {
      'medium' => WidgetDisplaySize.medium,
      'small' => WidgetDisplaySize.small,
      _ => WidgetDisplaySize.large,
    };
  }
}

enum WidgetPrivacyMode {
  full,
  blur,
  private;

  String get label => switch (this) {
    WidgetPrivacyMode.full => 'Full',
    WidgetPrivacyMode.blur => 'Blur',
    WidgetPrivacyMode.private => 'Private',
  };

  String get description => switch (this) {
    WidgetPrivacyMode.full => 'Show the clear photo full-screen on your widget.',
    WidgetPrivacyMode.blur => 'Blurred photo with sender details until opened.',
    WidgetPrivacyMode.private => 'Show only that you received a moment.',
  };

  static WidgetPrivacyMode fromValue(String value) {
    return WidgetPrivacyMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WidgetPrivacyMode.full,
    );
  }
}

class WidgetPreferences extends Equatable {
  const WidgetPreferences({
    required this.theme,
    required this.accentColor,
    required this.typography,
    required this.widgetMode,
    this.displaySize = WidgetDisplaySize.large,
    this.selectedPersonId,
    this.selectedCircleId,
    this.privacyMode = WidgetPrivacyMode.full,
    this.showSender = true,
    this.showTimestamp = true,
    this.showCaptions = false,
    this.lockScreenPrivacy = true,
    this.paused = false,
    this.privacyPersonId,
    this.privacyOverrides = const {},
    this.showStreak = true,
  });

  final WidgetTheme theme;
  final String accentColor;
  final WidgetTypography typography;
  final WidgetMode widgetMode;
  final WidgetDisplaySize displaySize;
  final String? selectedPersonId;
  final String? selectedCircleId;
  final WidgetPrivacyMode privacyMode;
  final bool showSender;
  final bool showTimestamp;
  final bool showCaptions;
  final bool lockScreenPrivacy;
  final bool paused;
  /// Legacy single-person scope. Prefer [privacyOverrides].
  final String? privacyPersonId;
  /// Per-sender privacy mode overrides (senderId -> mode).
  final Map<String, WidgetPrivacyMode> privacyOverrides;
  final bool showStreak;

  /// Resolves which privacy mode to use for a moment from [senderId].
  WidgetPrivacyMode privacyForSender(String senderId) {
    final override = privacyOverrides[senderId];
    if (override != null) return override;
    if (privacyPersonId == null) return privacyMode;
    if (privacyPersonId == senderId) return privacyMode;
    return WidgetPrivacyMode.full;
  }

  WidgetPreferences withPrivacyForPreview({String? senderId}) {
    if (senderId == null) return this;
    return copyWith(privacyMode: privacyForSender(senderId));
  }

  static const defaultAccent = '#FF6B8A';

  factory WidgetPreferences.defaults() {
    return const WidgetPreferences(
      theme: WidgetTheme.minimal,
      accentColor: defaultAccent,
      typography: WidgetTypography.defaultStyle,
      widgetMode: WidgetMode.latest,
      displaySize: WidgetDisplaySize.small,
    );
  }

  factory WidgetPreferences.fromJson(Map<String, dynamic> json) {
    return WidgetPreferences(
      theme: WidgetTheme.fromValue(json['theme'] as String? ?? 'minimal'),
      accentColor: json['accent_color'] as String? ?? defaultAccent,
      typography: WidgetTypography.fromValue(
        json['typography'] as String? ?? 'default',
      ),
      widgetMode: WidgetMode.fromValue(
        json['widget_mode'] as String? ?? 'latest',
      ),
      displaySize: WidgetDisplaySize.fromValue(
        json['display_size'] as String?,
      ),
      selectedPersonId: json['selected_person_id'] as String?,
      selectedCircleId: json['selected_circle_id'] as String?,
      privacyMode: WidgetPrivacyMode.fromValue(
        json['privacy_mode'] as String? ?? 'full',
      ),
      showSender: json['show_sender'] as bool? ?? true,
      showTimestamp: json['show_timestamp'] as bool? ?? true,
      showCaptions: json['show_captions'] as bool? ?? false,
      lockScreenPrivacy: json['lock_screen_privacy'] as bool? ?? true,
      paused: json['paused'] as bool? ?? false,
      privacyPersonId: json['privacy_person_id'] as String?,
      privacyOverrides: _parsePrivacyOverrides(json['privacy_overrides']),
      showStreak: json['show_streak'] as bool? ?? true,
    );
  }

  static Map<String, WidgetPrivacyMode> _parsePrivacyOverrides(Object? raw) {
    if (raw is! Map) return const {};
    return Map<String, WidgetPrivacyMode>.fromEntries(
      raw.entries.map((entry) {
        return MapEntry(
          entry.key.toString(),
          WidgetPrivacyMode.fromValue(entry.value.toString()),
        );
      }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'accent_color': accentColor,
      'typography': typography.wireValue,
      'widget_mode': widgetMode.name,
      'display_size': displaySize.wireValue,
      'selected_person_id': selectedPersonId,
      'selected_circle_id': selectedCircleId,
      'privacy_mode': privacyMode.name,
      'show_sender': showSender,
      'show_timestamp': showTimestamp,
      'show_captions': showCaptions,
      'lock_screen_privacy': lockScreenPrivacy,
      'paused': paused,
      'privacy_person_id': privacyPersonId,
      'privacy_overrides': {
        for (final entry in privacyOverrides.entries)
          entry.key: entry.value.name,
      },
      'show_streak': showStreak,
    };
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'p_theme': theme.name,
      'p_accent_color': accentColor,
      'p_typography': typography.wireValue,
      'p_widget_mode': widgetMode.name,
      'p_selected_person_id': widgetMode == WidgetMode.person
          ? selectedPersonId
          : null,
      'p_selected_circle_id': widgetMode == WidgetMode.circle
          ? selectedCircleId
          : null,
    };
  }

  Map<String, dynamic> toPrivacyJson() {
    return {
      'p_privacy_mode': privacyMode.name,
      'p_show_sender': showSender,
      'p_show_timestamp': showTimestamp,
      'p_show_captions': showCaptions,
      'p_lock_screen_privacy': lockScreenPrivacy,
      'p_paused': paused,
      'p_privacy_person_id': privacyPersonId,
      'p_privacy_overrides': {
        for (final entry in privacyOverrides.entries)
          entry.key: entry.value.name,
      },
    };
  }

  WidgetPreferences mergePrivacy(WidgetPreferences other) {
    return copyWith(
      privacyMode: other.privacyMode,
      showSender: other.showSender,
      showTimestamp: other.showTimestamp,
      showCaptions: other.showCaptions,
      lockScreenPrivacy: other.lockScreenPrivacy,
      paused: other.paused,
      privacyPersonId: other.privacyPersonId,
      clearPrivacyPerson: other.privacyPersonId == null,
      privacyOverrides: other.privacyOverrides,
    );
  }

  /// Applies device-local customization saved on this phone.
  WidgetPreferences mergeLocal(WidgetPreferences local) {
    return copyWith(
      theme: local.theme,
      accentColor: local.accentColor,
      typography: local.typography,
      widgetMode: local.widgetMode,
      displaySize: local.displaySize,
      selectedPersonId: local.widgetMode == WidgetMode.person
          ? local.selectedPersonId
          : null,
      selectedCircleId: local.widgetMode == WidgetMode.circle
          ? local.selectedCircleId
          : null,
      clearPerson: local.widgetMode != WidgetMode.person,
      clearCircle: local.widgetMode != WidgetMode.circle,
      privacyMode: local.privacyMode,
      showSender: local.showSender,
      showTimestamp: local.showTimestamp,
      showCaptions: local.showCaptions,
      lockScreenPrivacy: local.lockScreenPrivacy,
      paused: local.paused,
      privacyPersonId: local.privacyPersonId,
      clearPrivacyPerson: local.privacyPersonId == null,
      privacyOverrides: local.privacyOverrides,
      showStreak: local.showStreak,
    );
  }

  WidgetPreferences copyWith({
    WidgetTheme? theme,
    String? accentColor,
    WidgetTypography? typography,
    WidgetMode? widgetMode,
    WidgetDisplaySize? displaySize,
    String? selectedPersonId,
    String? selectedCircleId,
    WidgetPrivacyMode? privacyMode,
    bool? showSender,
    bool? showTimestamp,
    bool? showCaptions,
    bool? lockScreenPrivacy,
    bool? paused,
    String? privacyPersonId,
    Map<String, WidgetPrivacyMode>? privacyOverrides,
    bool? showStreak,
    bool clearPerson = false,
    bool clearCircle = false,
    bool clearPrivacyPerson = false,
  }) {
    return WidgetPreferences(
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      typography: typography ?? this.typography,
      widgetMode: widgetMode ?? this.widgetMode,
      displaySize: displaySize ?? this.displaySize,
      selectedPersonId: clearPerson
          ? null
          : selectedPersonId ?? this.selectedPersonId,
      selectedCircleId: clearCircle
          ? null
          : selectedCircleId ?? this.selectedCircleId,
      privacyMode: privacyMode ?? this.privacyMode,
      showSender: showSender ?? this.showSender,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      showCaptions: showCaptions ?? this.showCaptions,
      lockScreenPrivacy: lockScreenPrivacy ?? this.lockScreenPrivacy,
      paused: paused ?? this.paused,
      privacyPersonId: clearPrivacyPerson
          ? null
          : privacyPersonId ?? this.privacyPersonId,
      privacyOverrides: privacyOverrides ?? this.privacyOverrides,
      showStreak: showStreak ?? this.showStreak,
    );
  }

  @override
  List<Object?> get props => [
    theme,
    accentColor,
    typography,
    widgetMode,
    displaySize,
    selectedPersonId,
    selectedCircleId,
    privacyMode,
    showSender,
    showTimestamp,
    showCaptions,
    lockScreenPrivacy,
    paused,
    privacyPersonId,
    privacyOverrides,
    showStreak,
  ];
}

class WidgetPreferencesBundle extends Equatable {
  const WidgetPreferencesBundle({
    required this.preferences,
    required this.isPremium,
    required this.themes,
    required this.typographyOptions,
    required this.widgetModes,
    this.savedPreferences,
  });

  final WidgetPreferences preferences;
  final bool isPremium;
  final List<WidgetTheme> themes;
  final List<WidgetTypography> typographyOptions;
  final List<WidgetMode> widgetModes;
  final WidgetPreferences? savedPreferences;

  @override
  List<Object?> get props => [
    preferences,
    isPremium,
    themes,
    typographyOptions,
    widgetModes,
    savedPreferences,
  ];
}
