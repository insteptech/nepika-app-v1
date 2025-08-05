import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

class GetTodaysRoutine extends UseCase<List<Routine>, GetTodaysRoutineParams> {
  final RoutineRepository repository;

  GetTodaysRoutine(this.repository);

  @override
  Future<Result<List<Routine>>> call(GetTodaysRoutineParams params) async {
    return await repository.getTodaysRoutine(
      token: params.token,
      type: params.type,
    );
  }
}

class GetTodaysRoutineParams extends Equatable {
  final String token;
  final String type;

  const GetTodaysRoutineParams({
    required this.token,
    required this.type,
  });

  @override
  List<Object> get props => [token, type];
}
