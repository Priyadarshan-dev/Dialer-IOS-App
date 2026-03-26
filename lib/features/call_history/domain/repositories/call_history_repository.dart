import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/call_history_entity.dart';

abstract class CallHistoryRepository {
  Future<Either<Failure, List<CallHistoryEntity>>> getAllCalls();
  Future<Either<Failure, void>> saveCall(CallHistoryEntity call);
  Future<Either<Failure, void>> updateCallNotes(String id, String notes);
  Future<Either<Failure, void>> deleteCall(String id);
  Future<Either<Failure, void>> markCompleted(String id);
}
