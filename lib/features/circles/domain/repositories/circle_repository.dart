import 'dart:typed_data';

import 'package:moment/core/result/result.dart';
import 'package:moment/features/circles/domain/entities/circle.dart';

abstract class CircleRepository {
  Future<Result<List<Circle>>> getMyCircles();

  Future<Result<Map<String, CircleActivitySummary>>> getCircleActivitySummaries(
    List<String> circleIds,
  );

  Future<Result<Map<String, List<CircleMember>>>> getMembersForCircles(
    List<String> circleIds,
  );

  Future<Result<Circle>> getCircle(String circleId);

  Future<Result<List<CircleMember>>> getCircleMembers(String circleId);

  Future<Result<Circle>> createCircle(CreateCircleInput input);

  Future<Result<void>> addMember({
    required String circleId,
    required String userId,
  });

  Future<Result<void>> removeMember({
    required String circleId,
    required String userId,
  });

  Future<Result<Circle>> uploadCircleAvatar({
    required String circleId,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<Result<Circle>> updateCircleName({
    required String circleId,
    required String name,
  });

  Future<Result<void>> leaveCircle({required String circleId});

  Future<Result<void>> deleteCircle({required String circleId});
}
