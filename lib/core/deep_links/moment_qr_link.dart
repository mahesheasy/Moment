import 'package:moment/core/constants/app_constants.dart';

/// Personal Moment QR codes encode a user's profile id.
///
/// QR codes use the raw user id for reliable scanning from screens.
/// Shared links use `moment://friend/{userId}`.
abstract final class MomentQrLink {
  /// Compact payload for QR images — easier to scan from a phone screen.
  static String qrPayload(String userId) => userId.trim();

  /// Full deep link for sharing via text / other apps.
  static String friendProfile(String userId) =>
      '${AppConstants.deepLinkScheme}://friend/${userId.trim()}';

  /// Parses QR / share payloads into a profile user id.
  static String? parseUserId(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        uri.scheme.toLowerCase() == AppConstants.deepLinkScheme) {
      if (uri.host.toLowerCase() == 'friend') {
        if (uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty) {
          return _normalizeId(uri.pathSegments.first);
        }
        final queryId = uri.queryParameters['id'];
        if (queryId != null && queryId.isNotEmpty) {
          return _normalizeId(queryId);
        }
      }
    }

    return _normalizeId(trimmed);
  }

  static String? _normalizeId(String value) {
    final id = value.trim();
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (uuidPattern.hasMatch(id)) return id.toLowerCase();
    return null;
  }
}
