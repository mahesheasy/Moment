class PushBridge {
  const PushBridge();

  Future<String?> getToken() async => null;

  Future<bool> hasNotificationPermission() async => false;

  Future<bool> requestNotificationPermission() async => false;

  Future<void> deleteToken() async {}

  Future<void> syncNotificationPreferences(
    dynamic preferences,
  ) async {}
}
