class WidgetBackgroundReliabilityStatus {
  const WidgetBackgroundReliabilityStatus({
    required this.oem,
    required this.batteryUnrestricted,
    required this.needsAttention,
    required this.autostartGuidance,
  });

  factory WidgetBackgroundReliabilityStatus.fromMap(Map<dynamic, dynamic> map) {
    return WidgetBackgroundReliabilityStatus(
      oem: map['oem'] as String? ?? 'other',
      batteryUnrestricted: map['batteryUnrestricted'] as bool? ?? false,
      needsAttention: map['needsAttention'] as bool? ?? true,
      autostartGuidance: map['autostartGuidance'] as String? ?? '',
    );
  }

  final String oem;
  final bool batteryUnrestricted;
  final bool needsAttention;
  final String autostartGuidance;

  String get oemLabel => switch (oem) {
    'xiaomi' => 'Xiaomi / Redmi / POCO',
    'oppo' => 'Oppo',
    'vivo' => 'Vivo / iQOO',
    'oneplus' => 'OnePlus',
    'realme' => 'Realme',
    'samsung' => 'Samsung',
    _ => 'Android',
  };
}
