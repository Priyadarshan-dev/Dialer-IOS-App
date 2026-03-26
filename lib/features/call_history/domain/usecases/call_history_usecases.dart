import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/domain/repositories/call_history_repository.dart';

class GetAllCallsUseCase implements UseCase<List<CallHistoryEntity>, NoParams> {
  final CallHistoryRepository repository;

  GetAllCallsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CallHistoryEntity>>> call(NoParams params) async {
    return await repository.getAllCalls();
  }
}

class SaveCallUseCase implements UseCase<void, CallHistoryEntity> {
  final CallHistoryRepository repository;

  SaveCallUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CallHistoryEntity params) async {
    return await repository.saveCall(params);
  }
}

class UpdateCallNotesUseCase implements UseCase<void, UpdateNotesParams> {
  final CallHistoryRepository repository;

  UpdateCallNotesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateNotesParams params) async {
    return await repository.updateCallNotes(params.id, params.notes);
  }
}

class DeleteCallUseCase implements UseCase<void, String> {
  final CallHistoryRepository repository;

  DeleteCallUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteCall(params);
  }
}

class MarkCompletedUseCase implements UseCase<void, String> {
  final CallHistoryRepository repository;

  MarkCompletedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.markCompleted(params);
  }
}

class UpdateNotesParams {
  final String id;
  final String notes;

  UpdateNotesParams({required this.id, required this.notes});
}
