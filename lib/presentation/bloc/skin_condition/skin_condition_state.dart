import '../../../domain/skin_condition/entities/skin_condition_entities.dart';

abstract class SkinConditionState {}

class SkinConditionInitial extends SkinConditionState {}

class SkinConditionLoading extends SkinConditionState {}

class SkinConditionLoaded extends SkinConditionState {
  final SkinConditionEntity skinConditionDetails;

  SkinConditionLoaded({required this.skinConditionDetails});
}

class SkinConditionError extends SkinConditionState {
  final String message;

  SkinConditionError({required this.message});
}