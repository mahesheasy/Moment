import 'package:moment/core/result/result.dart';

abstract class SupportRepository {
  Future<Result<void>> submitReport({
    required String category,
    required String description,
  });
}
