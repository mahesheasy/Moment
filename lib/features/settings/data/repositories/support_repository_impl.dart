import 'package:moment/core/errors/failures.dart';
import 'package:moment/core/result/result.dart';
import 'package:moment/features/settings/data/datasources/support_remote_data_source.dart';
import 'package:moment/features/settings/domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._remote, this._userId);

  final SupportRemoteDataSource _remote;
  final String? Function() _userId;

  @override
  Future<Result<void>> submitReport({
    required String category,
    required String description,
  }) async {
    final userId = _userId();
    if (userId == null) return const Failed(AuthenticationFailure());

    final trimmedCategory = category.trim();
    final trimmedDescription = description.trim();
    if (trimmedCategory.length < 3) {
      return const Failed(
        ValidationFailure(message: 'Please choose a category.'),
      );
    }
    if (trimmedDescription.length < 10) {
      return const Failed(
        ValidationFailure(
          message: 'Please describe the problem in at least 10 characters.',
        ),
      );
    }

    try {
      await _remote.submitReport(
        userId: userId,
        category: trimmedCategory,
        description: trimmedDescription,
      );
      return const Success(null);
    } on Object catch (error) {
      if (error is Failure) return Failed(error);
      return Failed(_remote.mapError(error));
    }
  }
}
