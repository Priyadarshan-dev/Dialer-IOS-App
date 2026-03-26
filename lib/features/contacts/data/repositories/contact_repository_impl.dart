import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/features/contacts/domain/entities/contact_entity.dart';
import 'package:dialer_app_poc/features/contacts/domain/repositories/contact_repository.dart';
import 'package:dialer_app_poc/features/contacts/data/datasources/contact_local_datasource.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactLocalDataSource localDataSource;

  ContactRepositoryImpl(this.localDataSource);

@override
Future<Either<Failure, List<ContactEntity>>> getContacts() async {
  try {
    final models = await localDataSource.getContacts();
    return Right(models.map((m) => m.toEntity()).toList());
  } catch (e) {
    print('[DEBUG] ContactRepository: ACTUAL ERROR → $e'); // ← ADD THIS LINE
    print('[DEBUG] ContactRepository: ERROR TYPE → ${e.runtimeType}'); // ← ADD THIS LINE
    if (e.toString().contains('Permission denied')) {
      return Left(PermissionFailure('Contacts permission denied'));
    }
    return Left(DeviceFailure(e.toString()));
  }
}
}
