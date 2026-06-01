import 'failure.dart';

/// Resultado funcional sin dependencia externa (equivalente a dartz Either).
sealed class Either<L, R> {
  const Either();

  bool get isRight => this is Right<L, R>;
  bool get isLeft => this is Left<L, R>;

  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      onLeft(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) =>
      onRight(value);
}

typedef Result<T> = Either<Failure, T>;
