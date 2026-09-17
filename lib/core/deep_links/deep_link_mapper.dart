import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/constants/app_constants.dart';

class DeepLinkMapper {
  const DeepLinkMapper();

  String? locationFromUri(Uri uri) {
    if (uri.scheme != AppConstants.deepLinkScheme) {
      return null;
    }

    final host = uri.host;
    final segments = uri.pathSegments;
    final firstSegment = segments.isEmpty ? null : segments.first;

    switch (host) {
      case 'camera':
        return AppRoutes.camera;
      case 'moment':
        if (firstSegment == null || firstSegment.isEmpty) {
          return null;
        }
        return AppRoutes.moment(firstSegment);
      case 'widget':
        if (segments.length < 2) return null;
        final action = segments[0];
        final momentId = segments[1];
        if (momentId.isEmpty) return null;
        return switch (action) {
          'ping' => '${AppRoutes.moment(momentId)}?widgetAction=ping',
          'react' => '${AppRoutes.moment(momentId)}?widgetAction=react',
          _ => AppRoutes.moment(momentId),
        };
      case 'circle':
        if (firstSegment == null || firstSegment.isEmpty) {
          return null;
        }
        return AppRoutes.circle(firstSegment);
      case 'memory':
        if (firstSegment == null || firstSegment.isEmpty) {
          return null;
        }
        return AppRoutes.memory(firstSegment);
      case 'chat':
        if (firstSegment == null || firstSegment.isEmpty) {
          return null;
        }
        return AppRoutes.chatThread(firstSegment);
      case 'friends':
        return AppRoutes.friends;
      case 'friend':
        if (firstSegment == null || firstSegment.isEmpty) {
          final queryId = uri.queryParameters['id'];
          if (queryId == null || queryId.isEmpty) return null;
          return AppRoutes.friend(queryId);
        }
        return AppRoutes.friend(firstSegment);
      default:
        if (host.isEmpty && uri.path == AppRoutes.camera) {
          return AppRoutes.camera;
        }
        return null;
    }
  }
}
