import 'package:equatable/equatable.dart';
import '../utils/either.dart';

abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

abstract class NoParamsUseCase<Type> {
  Future<Result<Type>> call();
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
