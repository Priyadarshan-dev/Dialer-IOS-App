abstract class Failure {
  final String message;
  Failure(this.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class PermissionFailure extends Failure {
  PermissionFailure(super.message);
}

class DeviceFailure extends Failure {
  DeviceFailure(super.message);
}
