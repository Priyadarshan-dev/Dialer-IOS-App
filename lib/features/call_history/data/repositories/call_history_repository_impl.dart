import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/features/call_history/domain/entities/call_history_entity.dart';
import 'package:dialer_app_poc/features/call_history/domain/repositories/call_history_repository.dart';
import 'package:dialer_app_poc/features/call_history/data/datasources/call_history_local_datasource.dart';
import 'package:dialer_app_poc/features/call_history/data/models/call_history_model.dart';

class CallHistoryRepositoryImpl implements CallHistoryRepository {
  final CallHistoryLocalDataSource localDataSource;

  CallHistoryRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<CallHistoryEntity>>> getAllCalls() async {
    try {
      final models = await localDataSource.getAllCalls();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCall(CallHistoryEntity call) async {
    try {
      await localDataSource.saveCall(CallHistoryModel.fromEntity(call));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCallNotes(String id, String notes) async {
    try {
      await localDataSource.updateCallNotes(id, notes);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCall(String id) async {
    try {
      await localDataSource.deleteCall(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markCompleted(String id) async {
    try {
      await localDataSource.markCompleted(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
