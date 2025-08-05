import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../repositories/routine_repository.dart';

class UpdateRoutineStep extends UseCase<void, UpdateRoutineStepParams> {
  final RoutineRepository repository;

  UpdateRoutineStep(this.repository);

  @override
  Future<Result<void>> call(UpdateRoutineStepParams params) async {
    return await repository.updateRoutineStep(
      token: params.token,
      stepId: params.stepId,
      isCompleted: params.isCompleted,
    );
  }
}

class UpdateRoutineStepParams extends Equatable {
  final String token;
  final String stepId;
  final bool isCompleted;

  const UpdateRoutineStepParams({
    required this.token,
    required this.stepId,
    required this.isCompleted,
  });

  @override
  List<Object> get props => [token, stepId, isCompleted];
}
