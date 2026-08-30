class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String onboarding = '/onboarding';
  static const String setupPermissions = '/setup/permissions';
  static const String home = '/home';
  static const String camera = '/camera';
  static const String friends = '/friends';
  static const String circles = '/circles';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String premium = '/premium';
  static const String widgetCustomize = '/widget-customize';
  static const String widgetSettings = '/settings/widget';
  static const String widgetPrivacy = '/settings/widget-privacy';
  static const String blockedUsers = '/settings/blocked';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/settings/notification-settings';
  static const String appearance = '/settings/appearance';
  static const String help = '/settings/help';
  static const String reportProblem = '/settings/report-problem';
  static const String timeTravel = '/time-travel';

  static String moment(String id, {String? heroScope}) {
    final path = '/moment/$id';
    if (heroScope == null || heroScope.isEmpty) return path;
    return '$path?heroScope=$heroScope';
  }

  static String chatThread(String userId) => '/chat/$userId';

  static String friend(String id) => '/friends/$id';

  static String cameraForPrompt({
    required String circleId,
    required String promptId,
  }) => '$camera?circleId=$circleId&promptId=$promptId';

  static String cameraForCircle(String circleId) => '$camera?circleId=$circleId';

  static String circleToday(String circleId) => '/circles/$circleId/today';
  static String circleMoments(String circleId) => '/circles/$circleId/moments';
  static String circle(String id) => '/circles/$id';
  static String memoryEdit(String id) => '/memories/$id/edit';
  static String memory(String id) => '/memories/$id';
}
