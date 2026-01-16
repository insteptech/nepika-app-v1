import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/support/entities/faq.dart';
import '../../../domain/support/usecases/get_faqs.dart';
import '../../../core/error/failures.dart';

// Events
abstract class FaqEvent extends Equatable {
  const FaqEvent();
  @override
  List<Object?> get props => [];
}

class GetFaqsEvent extends FaqEvent {}

// States
abstract class FaqState extends Equatable {
  const FaqState();
  @override
  List<Object?> get props => [];
}

class FaqInitial extends FaqState {}
class FaqLoading extends FaqState {}

class FaqLoaded extends FaqState {
  final List<Faq> faqs;

  const FaqLoaded(this.faqs);

  @override
  List<Object?> get props => [faqs];
}

class FaqError extends FaqState {
  final String message;

  const FaqError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class FaqBloc extends Bloc<FaqEvent, FaqState> {
  final GetFaqs getFaqs;

  FaqBloc({required this.getFaqs}) : super(FaqInitial()) {
    on<GetFaqsEvent>(_onGetFaqs);
  }

  Future<void> _onGetFaqs(GetFaqsEvent event, Emitter<FaqState> emit) async {
    emit(FaqLoading());
    final result = await getFaqs();
    result.fold(
      (failure) {
        String message = 'Failed to load FAQs';
        if (failure is ServerFailure) message = failure.message;
        if (failure is NetworkFailure) message = failure.message;
        emit(FaqError(message));
      },
      (faqs) => emit(FaqLoaded(faqs)),
    );
  }
}
