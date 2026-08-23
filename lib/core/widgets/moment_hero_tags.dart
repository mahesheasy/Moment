/// Shared Hero flight tags — scoped so IndexedStack tabs never collide.
abstract final class MomentHeroTags {
  static const scopeHome = 'home';
  static const scopeMemories = 'memories';

  static String photo(String momentId, {String scope = scopeHome}) =>
      'moment-photo-$scope-$momentId';

  static String circleMember(String circleId, String userId) =>
      'circle-member-$circleId-$userId';
}
