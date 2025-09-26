import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/onboarding/entities/onboarding_entites.dart';
import '../../../../domain/onboarding/repositories/onboarding_repositories.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';
import '../../utils/onboarding_validator.dart';
import '../../utils/visibility_evaluator.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository repository;
  final OnboardingValidator validator;
  final VisibilityEvaluator visibilityEvaluator;

  OnboardingBloc({
    required this.repository,
    required this.validator,
    required this.visibilityEvaluator,
  }) : super(const OnboardingInitial()) {
    on<LoadOnboardingStep>(_onLoadOnboardingStep);
    on<UpdateAnswer>(_onUpdateAnswer);
    on<ValidateStep>(_onValidateStep);
    on<SubmitCurrentStep>(_onSubmitCurrentStep);
    on<NavigateToNextStep>(_onNavigateToNextStep);
    on<NavigateToPreviousStep>(_onNavigateToPreviousStep);
    on<SkipCurrentStep>(_onSkipCurrentStep);
    on<SkipAndFetchNextStep>(_onSkipAndFetchNextStep);
    on<ResetOnboarding>(_onResetOnboarding);
  }

  Future<void> _onLoadOnboardingStep(
    LoadOnboardingStep event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      emit(const OnboardingLoading());

      final screenData = await repository.fetchQuestions(
        userId: event.userId,
        screenSlug: event.screenSlug,
        token: event.token,
      );

      final currentState = state;
      Map<String, dynamic> answers = {};
      Map<String, String> selectedOptions = {};
      List<Map<String, dynamic>> responses = [];
      int currentStep = 1;

      // Preserve existing state if coming from a step transition
      if (currentState is OnboardingStepLoaded) {
        currentStep = currentState.currentStep;
      }

      // Process prefilled values and selected options
      final processedData = _processScreenData(screenData);
      answers = processedData['answers'];
      selectedOptions = processedData['selectedOptions'];
      responses = processedData['responses'];

      final isFormValid = validator.validateAnswers(
        screenData.questions,
        answers,
        responses,
        visibilityEvaluator,
      );

      emit(OnboardingStepLoaded(
        screenData: screenData,
        answers: answers,
        selectedOptions: selectedOptions,
        responses: responses,
        isFormValid: isFormValid,
        currentStep: currentStep,
      ));
    } catch (e) {
      emit(OnboardingError(message: 'Failed to load onboarding step: $e'));
    }
  }

  void _onUpdateAnswer(
    UpdateAnswer event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is! OnboardingStepLoaded) return;

    final updatedAnswers = Map<String, dynamic>.from(currentState.answers);
    final updatedSelectedOptions = Map<String, String>.from(currentState.selectedOptions);
    final updatedResponses = List<Map<String, dynamic>>.from(currentState.responses);

    // Find the question being updated
    final question = currentState.screenData.questions.firstWhere(
      (q) => q.slug == event.questionSlug,
    );

    _updateAnswerData(
      question,
      event.value,
      updatedAnswers,
      updatedSelectedOptions,
      updatedResponses,
    );

    // Apply validation rules (exclusivity, etc.)
    _applyValidationRules(
      question,
      event.value,
      currentState.screenData.questions,
      updatedAnswers,
      updatedSelectedOptions,
      updatedResponses,
    );

    // Clear responses for invisible questions
    _clearInvisibleQuestionResponses(
      currentState.screenData.questions,
      updatedAnswers,
      updatedSelectedOptions,
      updatedResponses,
    );

    final isFormValid = validator.validateAnswers(
      currentState.screenData.questions,
      updatedAnswers,
      updatedResponses,
      visibilityEvaluator,
    );

    emit(currentState.copyWith(
      answers: updatedAnswers,
      selectedOptions: updatedSelectedOptions,
      responses: updatedResponses,
      isFormValid: isFormValid,
    ));
  }

  void _onValidateStep(
    ValidateStep event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is! OnboardingStepLoaded) return;

    final isFormValid = validator.validateAnswers(
      currentState.screenData.questions,
      currentState.answers,
      currentState.responses,
      visibilityEvaluator,
    );

    emit(currentState.copyWith(isFormValid: isFormValid));
  }

  Future<void> _onSubmitCurrentStep(
    SubmitCurrentStep event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OnboardingStepLoaded) return;

    if (!currentState.isFormValid) {
      emit(const OnboardingError(message: 'Please answer all required questions'));
      return;
    }

    try {
      emit(const OnboardingStepSubmitting());

      final payload = _buildSubmissionPayload(currentState.responses);

      debugPrint("Submitting payload JSON: ${jsonEncode(payload)}");

      final submissionResponse = await repository.submitAnswers(
        userId: event.userId,
        screenSlug: event.screenSlug,
        token: event.token,
        answers: payload,
      );

      debugPrint("📈 Submission response - activeStep: ${submissionResponse.activeStep}, completed: ${submissionResponse.onboardingCompleted}");

      if (submissionResponse.onboardingCompleted) {
        emit(const OnboardingCompleted());
      } else {
        emit(OnboardingStepSubmitted(
          message: submissionResponse.message,
          nextStep: submissionResponse.activeStep,
        ));
      }
    } catch (e) {
      emit(OnboardingError(message: 'Failed to submit answers: $e'));
    }
  }

  void _onNavigateToNextStep(
    NavigateToNextStep event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is! OnboardingStepLoaded) return;

    final totalSteps = currentState.screenData.totalSteps ?? 7;
    final nextStep = currentState.currentStep + 1;

    if (nextStep > totalSteps) {
      emit(const OnboardingCompleted());
    } else {
      // Reset form data for next step
      emit(OnboardingStepLoaded(
        screenData: currentState.screenData,
        answers: {},
        selectedOptions: {},
        responses: [],
        isFormValid: false,
        currentStep: nextStep,
      ));
    }
  }

  void _onNavigateToPreviousStep(
    NavigateToPreviousStep event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is! OnboardingStepLoaded) return;

    final previousStep = currentState.currentStep - 1;
    if (previousStep < 1) return;

    // Reset form data for previous step
    emit(OnboardingStepLoaded(
      screenData: currentState.screenData,
      answers: {},
      selectedOptions: {},
      responses: [],
      isFormValid: false,
      currentStep: previousStep,
    ));
  }

  void _onSkipCurrentStep(
    SkipCurrentStep event,
    Emitter<OnboardingState> emit,
  ) {
    add(const NavigateToNextStep());
  }

  Future<void> _onSkipAndFetchNextStep(
    SkipAndFetchNextStep event,
    Emitter<OnboardingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OnboardingStepLoaded) return;

    try {
      // Calculate next step
      final nextStep = event.currentStep + 1;
      final totalSteps = currentState.screenData.totalSteps ?? 7;

      debugPrint('⏭️ Skipping from step ${event.currentStep} to step $nextStep (total: $totalSteps)');

      // Check if we've reached the end
      if (nextStep > totalSteps) {
        debugPrint('🏁 Onboarding completed via skip');
        emit(const OnboardingCompleted());
        return;
      }

      // Emit loading state
      emit(const OnboardingLoading());

      // Fetch the next step data from the server
      final screenData = await repository.fetchQuestions(
        userId: event.userId,
        screenSlug: nextStep.toString(),
        token: event.token,
      );

      // Process the new screen data
      final processedData = _processScreenData(screenData);
      final answers = processedData['answers'] as Map<String, dynamic>;
      final selectedOptions = processedData['selectedOptions'] as Map<String, String>;
      final responses = processedData['responses'] as List<Map<String, dynamic>>;

      // Validate the new step
      final isFormValid = validator.validateAnswers(
        screenData.questions,
        answers,
        responses,
        visibilityEvaluator,
      );

      // Emit the new step loaded state
      emit(OnboardingStepLoaded(
        screenData: screenData,
        answers: answers,
        selectedOptions: selectedOptions,
        responses: responses,
        isFormValid: isFormValid,
        currentStep: nextStep,
      ));

      debugPrint('✅ Successfully loaded step $nextStep after skip');
    } catch (e) {
      debugPrint('❌ Error skipping to next step: $e');
      emit(OnboardingError(message: 'Failed to load next step: $e'));
    }
  }

  void _onResetOnboarding(
    ResetOnboarding event,
    Emitter<OnboardingState> emit,
  ) {
    emit(const OnboardingInitial());
  }

  // Helper Methods

  Map<String, dynamic> _processScreenData(OnboardingScreenDataEntity screenData) {
    final Map<String, dynamic> answers = {};
    final Map<String, String> selectedOptions = {};
    final List<Map<String, dynamic>> responses = [];

    for (final question in screenData.questions) {
      dynamic prefilledValue;
      if (screenData.user != null && question.targetField.isNotEmpty) {
        prefilledValue = screenData.user![question.targetField];
      }
      if (prefilledValue == null && question.prefillValue != null) {
        prefilledValue = question.prefillValue;
      }

      if (prefilledValue != null) {
        _processPrefillValue(
          question,
          prefilledValue,
          answers,
          selectedOptions,
          responses,
        );
      }

      // Process is_selected flags from backend
      _processSelectedOptions(
        question,
        answers,
        selectedOptions,
        responses,
      );
    }

    return {
      'answers': answers,
      'selectedOptions': selectedOptions,
      'responses': responses,
    };
  }

  void _processPrefillValue(
    OnboardingQuestionEntity question,
    dynamic prefilledValue,
    Map<String, dynamic> answers,
    Map<String, String> selectedOptions,
    List<Map<String, dynamic>> responses,
  ) {
    if (question.inputType == "single_choice" || question.inputType == "dropdown") {
      final matchOpt = question.options.firstWhere(
        (o) =>
            o.text == prefilledValue.toString() ||
            o.id == prefilledValue.toString() ||
            o.value == prefilledValue.toString(),
        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
      );
      if (matchOpt.id.isNotEmpty) {
        selectedOptions[question.slug] = matchOpt.id;
        answers[question.slug] = matchOpt.value;
        responses.add({
          "question_id": question.id,
          "option_id": matchOpt.id,
          "value": matchOpt.text,
        });
      }
    } else {
      answers[question.slug] = prefilledValue;
      responses.add({
        "question_id": question.id,
        "value": prefilledValue.toString(),
      });
    }
  }

  void _processSelectedOptions(
    OnboardingQuestionEntity question,
    Map<String, dynamic> answers,
    Map<String, String> selectedOptions,
    List<Map<String, dynamic>> responses,
  ) {
    if (question.inputType == "multi_choice" || question.inputType == "checkbox") {
      if (answers[question.slug] == null || answers[question.slug] is! List<String>) {
        answers[question.slug] = <String>[];
      }

      final selectedOptions = question.options.where((o) => o.isSelected).toList();
      for (final opt in selectedOptions) {
        final answersList = answers[question.slug] as List<String>;
        if (!answersList.contains(opt.id)) {
          answersList.add(opt.id);
        }

        bool alreadyInResponses = responses.any((r) => 
          r['question_id'] == question.id && r['option_id'] == opt.id);
        if (!alreadyInResponses) {
          responses.add({
            "question_id": question.id,
            "option_id": opt.id,
            "value": opt.text,
          });
        }
      }
    } else if ((question.inputType == "single_choice" || question.inputType == "dropdown") && 
               !selectedOptions.containsKey(question.slug)) {
      final opt = question.options.firstWhere(
        (o) => o.isSelected,
        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
      );
      if (opt.id.isNotEmpty) {
        selectedOptions[question.slug] = opt.id;
        answers[question.slug] = opt.value;
        responses.add({
          "question_id": question.id,
          "option_id": opt.id,
          "value": opt.text,
        });
      }
    }
  }

  void _updateAnswerData(
    OnboardingQuestionEntity question,
    dynamic value,
    Map<String, dynamic> answers,
    Map<String, String> selectedOptions,
    List<Map<String, dynamic>> responses,
  ) {
    // Remove existing responses for this question
    responses.removeWhere((r) => r['question_id'] == question.id);

    if (question.inputType == "single_choice" || question.inputType == "dropdown") {
      final selectedOption = question.options.firstWhere(
        (o) => o.id == value,
        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
      );
      if (selectedOption.id.isNotEmpty) {
        selectedOptions[question.slug] = selectedOption.id;
        answers[question.slug] = selectedOption.value;
        responses.add({
          "question_id": question.id,
          "option_id": selectedOption.id,
          "value": selectedOption.text,
        });
      }
    } else if (question.inputType == "multi_choice" || question.inputType == "checkbox") {
      answers[question.slug] = value;
      selectedOptions.remove(question.slug);
      if (value is List<dynamic>) {
        for (var id in value) {
          final opt = question.options.firstWhere(
            (o) => o.id == id,
            orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
          );
          if (opt.id.isNotEmpty) {
            responses.add({
              "question_id": question.id,
              "option_id": id,
              "value": opt.text,
            });
          }
        }
      }
    } else {
      answers[question.slug] = value;
      responses.add({"question_id": question.id, "value": value});
    }
  }

  void _applyValidationRules(
    OnboardingQuestionEntity question,
    dynamic selectedValue,
    List<OnboardingQuestionEntity> allQuestions,
    Map<String, dynamic> answers,
    Map<String, String> selectedOptions,
    List<Map<String, dynamic>> responses,
  ) {
    final validationRules = question.validationRules;
    if (validationRules == null) return;

    final rule = validationRules['rule'] as String?;
    if (rule != 'exclusive') return;

    final excludes = validationRules['excludes'] as List<dynamic>?;
    if (excludes == null || excludes.isEmpty) return;

    // If this question was selected, clear excluded questions
    if (selectedValue != null && selectedValue.toString().isNotEmpty) {
      for (final excludedSlug in excludes) {
        if (excludedSlug is String) {
          answers.remove(excludedSlug);
          selectedOptions.remove(excludedSlug);
          final excludedQuestion = allQuestions.firstWhere(
            (q) => q.slug == excludedSlug,
            orElse: () => OnboardingQuestionEntity(
              id: '', slug: '', questionText: '', targetField: '', 
              targetTable: '', inputType: '', isRequired: false, 
              displayOrder: 0, options: []
            ),
          );
          if (excludedQuestion.id.isNotEmpty) {
            responses.removeWhere((r) => r['question_id'] == excludedQuestion.id);
          }
        }
      }
    }

    // Handle reverse exclusivity
    _handleReverseExclusivity(
      question.slug,
      allQuestions,
      answers,
      selectedOptions,
      responses,
    );
  }

  void _handleReverseExclusivity(
    String currentQuestionSlug,
    List<OnboardingQuestionEntity> allQuestions,
    Map<String, dynamic> answers,
    Map<String, String> selectedOptions,
    List<Map<String, dynamic>> responses,
  ) {
    for (final exclusiveQuestion in allQuestions) {
      final validationRules = exclusiveQuestion.validationRules;
      if (validationRules?['rule'] == 'exclusive') {
        final excludes = validationRules?['excludes'] as List<dynamic>?;
        if (excludes != null && excludes.contains(currentQuestionSlug)) {
          answers.remove(exclusiveQuestion.slug);
          selectedOptions.remove(exclusiveQuestion.slug);
          responses.removeWhere((r) => r['question_id'] == exclusiveQuestion.id);
        }
      }
    }
  }

  void _clearInvisibleQuestionResponses(
    List<OnboardingQuestionEntity> questions,
    Map<String, dynamic> answers,
    Map<String, String> selectedOptions,
    List<Map<String, dynamic>> responses,
  ) {
    final invisibleQuestions = questions.where((q) => 
      !visibilityEvaluator.evaluateVisibility(q.visibilityConditions, answers)
    ).toList();
    
    for (final question in invisibleQuestions) {
      answers.remove(question.slug);
      selectedOptions.remove(question.slug);
      responses.removeWhere((r) => r['question_id'] == question.id);
    }
  }

  Map<String, dynamic> _buildSubmissionPayload(List<Map<String, dynamic>> responses) {
    return {
      "responses": responses
          .map((r) => {
                "question_id": r["question_id"].toString(),
                if (r.containsKey("option_id") && r["option_id"] != null)
                  "option_id": r["option_id"].toString(),
                "value": r["value"],
              })
          .toList(),
    };
  }
}