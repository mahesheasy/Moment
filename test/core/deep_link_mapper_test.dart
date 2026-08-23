import 'package:flutter_test/flutter_test.dart';
import 'package:moment/app/router/app_routes.dart';
import 'package:moment/core/deep_links/deep_link_mapper.dart';

void main() {
  const mapper = DeepLinkMapper();

  test('maps camera, moment, circle, and memory deep links', () {
    expect(
      mapper.locationFromUri(Uri.parse('moment://camera')),
      AppRoutes.camera,
    );
    expect(
      mapper.locationFromUri(Uri.parse('moment://moment/abc')),
      AppRoutes.moment('abc'),
    );
    expect(
      mapper.locationFromUri(Uri.parse('moment://circle/family')),
      AppRoutes.circle('family'),
    );
    expect(
      mapper.locationFromUri(Uri.parse('moment://widget/ping/abc')),
      '${AppRoutes.moment('abc')}?widgetAction=ping',
    );
    expect(
      mapper.locationFromUri(Uri.parse('moment://widget/react/abc')),
      '${AppRoutes.moment('abc')}?widgetAction=react',
    );
  });

  test('rejects foreign schemes and incomplete ids', () {
    expect(mapper.locationFromUri(Uri.parse('https://example.com')), isNull);
    expect(mapper.locationFromUri(Uri.parse('moment://moment')), isNull);
  });
}
