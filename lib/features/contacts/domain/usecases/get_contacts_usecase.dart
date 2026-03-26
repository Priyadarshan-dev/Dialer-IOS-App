import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/entities/contact_entity.dart';
import 'package:dialer_app_poc/features/contacts/domain/repositories/contact_repository.dart';

class GetContactsUseCase implements UseCase<List<ContactEntity>, NoParams> {
  final ContactRepository repository;

  GetContactsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ContactEntity>>> call(NoParams params) async {
    return await repository.getContacts();
  }
}
