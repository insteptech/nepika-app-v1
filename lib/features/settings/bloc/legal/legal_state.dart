import 'package:equatable/equatable.dart';
import '../../../../domain/settings/entities/legal_document_entity.dart';

abstract class LegalState extends Equatable {
  const LegalState();

  @override
  List<Object?> get props => [];
}

class LegalInitial extends LegalState {}

class LegalLoading extends LegalState {}

class LegalLoaded extends LegalState {
  final LegalDocumentEntity document;

  const LegalLoaded(this.document);

  @override
  List<Object?> get props => [document];
}

class LegalError extends LegalState {
  final String message;

  const LegalError(this.message);

  @override
  List<Object?> get props => [message];
}
