/// Fallos de dominio para repositorios que retornan [Either].
class Failure {
  final String message;
  const Failure(this.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de almacenamiento local']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión de red']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
