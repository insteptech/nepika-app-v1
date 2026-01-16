import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/support/usecases/submit_feedback.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class SubmitFeedbackEvent extends FeedbackEvent {
  final String text;
  final int? rating;

  const SubmitFeedbackEvent({required this.text, this.rating});

  @override
  List<Object?> get props => [text, rating];
}

abstract class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {}

class FeedbackSubmitting extends FeedbackState {}

class FeedbackSuccess extends FeedbackState {}

class FeedbackError extends FeedbackState {
  final String message;

  const FeedbackError(this.message);

  @override
  List<Object?> get props => [message];
}

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final SubmitFeedback submitFeedback;

  FeedbackBloc({required this.submitFeedback}) : super(FeedbackInitial()) {
    on<SubmitFeedbackEvent>(_onSubmitFeedback);
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedbackEvent event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackSubmitting());

    final result = await submitFeedback(
      text: event.text,
      rating: event.rating,
    );

    result.fold(
      (failure) => emit(FeedbackError(failure.message)),
      (_) => emit(FeedbackSuccess()),
    );
  }
}
