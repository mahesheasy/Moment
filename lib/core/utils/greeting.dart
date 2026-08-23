String timeSensitiveGreeting({String? name}) {
  final hour = DateTime.now().hour;
  final greeting = hour < 12
      ? 'Good morning'
      : hour < 17
      ? 'Good afternoon'
      : 'Good evening';
  final first = firstNameOf(name);
  if (first.isEmpty) return greeting;
  return '$greeting, $first';
}

String firstNameOf(String? displayName) {
  if (displayName == null) return '';
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}
