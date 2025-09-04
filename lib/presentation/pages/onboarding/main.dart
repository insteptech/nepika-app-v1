import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/presentation/pages/onboarding/components/skeleton.dart';
import 'package:nepika/presentation/pages/onboarding/components/something_went_wrong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/widgets/base_question_page.dart';
import 'package:nepika/core/widgets/option_selector.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/data/onboarding/datasources/onboarding_remote_datasource.dart';
import 'package:nepika/data/onboarding/repositories/onboarding_repository.dart';
import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';
import 'package:nepika/presentation/bloc/onboarding/onboarding_bloc.dart';

class OnboardingMapper extends StatefulWidget {
  const OnboardingMapper({super.key});

  @override
  State<OnboardingMapper> createState() => _OnboardingMapperState();
}

class _OnboardingMapperState extends State<OnboardingMapper> with WidgetsBindingObserver {
  
  late OnboardingBloc _bloc;
  int _currentStep = 1;
  String? userId;
  String? token;
  bool _loading = true;

  Map<String, String> _selected = {};
  Map<String, dynamic> _answers = {};
  List<Map<String, dynamic>> _responses = [];

  bool _isFormValid = false;
  int _requiredQuestionCount = 0;
  String? appLanguageCode;
  List<OnboardingQuestionEntity> _questions = [];

  Map<String, dynamic> _screen = {
    'id': 1,
    'slug': 'basic-info',
    'title': 'Tell us about yourself',
    'subtitle': 'Your answers will help us personalize your experience.',
  };

  final prefHelper = SharedPrefsHelper();
  final secureStorage = SecureStorage();

  // Utility function to evaluate visibility conditions
  bool evaluateVisibility(
    Map<String, dynamic>? conditions,
    Map<String, dynamic> responses,
  ) {
    if (conditions == null) return true;
    
    debugPrint("🔍 Evaluating visibility: conditions=$conditions, responses=$responses");
    
    final operator = conditions['operator'] as String?;
    final questionSlug = conditions['question_slug'] as String?;
    final expectedValue = conditions['value'];
    
    if (operator == null || questionSlug == null || expectedValue == null) {
      return true; // Show by default if condition is malformed
    }
    
    // Get the actual response value for the referenced question
    final actualValue = responses[questionSlug];
    
    switch (operator) {
      case 'equals':
        return actualValue?.toString() == expectedValue.toString();
      case 'not_equals':
        return actualValue?.toString() != expectedValue.toString();
      case 'in':
        if (expectedValue is List && actualValue is List) {
          return actualValue.any((val) => expectedValue.contains(val));
        }
        if (expectedValue is List) {
          return expectedValue.contains(actualValue);
        }
        return false;
      case 'not_in':
        if (expectedValue is List && actualValue is List) {
          return !actualValue.any((val) => expectedValue.contains(val));
        }
        if (expectedValue is List) {
          return !expectedValue.contains(actualValue);
        }
        return true;
      default:
        return true; // Show by default for unknown operators
    }
  }

  // Utility function to apply validation rules
  void applyValidationRules(
    OnboardingQuestionEntity question,
    dynamic selectedValue,
    Map<String, dynamic> responses,
    Function(Map<String, dynamic>) setResponses,
  ) {
    final validationRules = question.validationRules;
    if (validationRules == null) return;
    
    final rule = validationRules['rule'] as String?;
    if (rule != 'exclusive') return;
    
    final excludes = validationRules['excludes'] as List<dynamic>?;
    if (excludes == null || excludes.isEmpty) return;
    
    // If this question was selected, clear excluded questions
    if (selectedValue != null && selectedValue.toString().isNotEmpty) {
      final updatedResponses = Map<String, dynamic>.from(responses);
      
      for (final excludedSlug in excludes) {
        if (excludedSlug is String) {
          updatedResponses.remove(excludedSlug);
          // Also remove from _selected and _responses arrays
          _selected.remove(excludedSlug);
          final excludedQuestion = _questions.firstWhere(
            (q) => q.slug == excludedSlug,
            orElse: () => OnboardingQuestionEntity(
              id: '', slug: '', questionText: '', targetField: '', 
              targetTable: '', inputType: '', isRequired: false, 
              displayOrder: 0, options: []
            ),
          );
          if (excludedQuestion.id.isNotEmpty) {
            _responses.removeWhere((r) => r['question_id'] == excludedQuestion.id);
          }
        }
      }
      
      setResponses(updatedResponses);
    }
  }

  // Helper function to check if any excluded question is selected for exclusivity rules
  bool isExclusiveQuestionConflicted(OnboardingQuestionEntity question, Map<String, dynamic> responses) {
    final validationRules = question.validationRules;
    if (validationRules == null) return false;
    
    final rule = validationRules['rule'] as String?;
    if (rule != 'exclusive') return false;
    
    final excludes = validationRules['excludes'] as List<dynamic>?;
    if (excludes == null || excludes.isEmpty) return false;
    
    // Check if any excluded question has a value
    for (final excludedSlug in excludes) {
      if (excludedSlug is String && responses.containsKey(excludedSlug)) {
        final value = responses[excludedSlug];
        if (value != null && value.toString().isNotEmpty) {
          return true; // There's a conflict
        }
      }
    }
    
    return false;
  }

  // Helper method to handle reverse exclusivity
  void _handleReverseExclusivity(String currentQuestionSlug) {
    // Find exclusive questions that should be cleared when current question is selected
    for (final exclusiveQuestion in _questions) {
      final validationRules = exclusiveQuestion.validationRules;
      if (validationRules?['rule'] == 'exclusive') {
        final excludes = validationRules?['excludes'] as List<dynamic>?;
        if (excludes != null && excludes.contains(currentQuestionSlug)) {
          // Clear the exclusive question
          setState(() {
            _answers.remove(exclusiveQuestion.slug);
            _selected.remove(exclusiveQuestion.slug);
            _responses.removeWhere((r) => r['question_id'] == exclusiveQuestion.id);
          });
          debugPrint("🗑️ Cleared exclusive question ${exclusiveQuestion.slug} because ${currentQuestionSlug} was selected");
        }
      }
    }
  }

  // Helper method to clear responses for invisible questions
  void _clearInvisibleQuestionResponses() {
    final invisibleQuestions = _questions.where((q) => 
      !evaluateVisibility(q.visibilityConditions, _answers)
    ).toList();
    
    setState(() {
      for (final question in invisibleQuestions) {
        // Remove from answers map
        _answers.remove(question.slug);
        _selected.remove(question.slug);
        
        // Remove from responses list
        _responses.removeWhere((r) => r['question_id'] == question.id);
        
        debugPrint("🗑️ Cleared response for invisible question: ${question.slug}");
      }
    });
  }
  
  // Helper method to ensure dropdown values are valid (safe for build phase)
  String? _getSafeDropdownValue(OnboardingQuestionEntity question) {
    if (question.inputType != "dropdown") return null;
    
    final selectedId = _selected[question.slug];
    final answersValue = _answers[question.slug];
    
    debugPrint("🔍 _getSafeDropdownValue for ${question.slug}: selectedId=$selectedId, answersValue=$answersValue");
    
    // First check if selected ID is valid
    if (selectedId != null) {
      final optionExists = question.options.any((opt) => opt.id == selectedId);
      if (optionExists) {
        debugPrint("✅ Found valid selected ID: $selectedId");
        return selectedId;
      }
    }
    
    // If no valid selected ID, try to find option by answer value
    if (answersValue != null) {
      final matchingOption = question.options.firstWhere(
        (opt) => opt.value == answersValue.toString() || opt.id == answersValue.toString(),
        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
      );
      if (matchingOption.id.isNotEmpty) {
        debugPrint("✅ Found matching option by value: ${answersValue} -> ${matchingOption.id}");
        return matchingOption.id;
      }
    }
    
    // Try to find by prefillValue if it's available
    if (question.prefillValue != null) {
      final matchingOption = question.options.firstWhere(
        (opt) => opt.text == question.prefillValue || 
                opt.value == question.prefillValue ||
                opt.id == question.prefillValue,
        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
      );
      if (matchingOption.id.isNotEmpty) {
        debugPrint("✅ Found matching option by prefillValue: ${question.prefillValue} -> ${matchingOption.id}");
        return matchingOption.id;
      }
    }
    
    debugPrint("❌ No valid dropdown value found for ${question.slug}");
    return null;
  }
  
  // Method to fix dropdown values (can call setState)  
  void _fixDropdownValues() {
    bool needsUpdate = false;
    
    for (final question in _questions) {
      if (question.inputType != "dropdown") continue;
      
      final selectedId = _selected[question.slug];
      final answersValue = _answers[question.slug];
      
      debugPrint("🔍 Fixing dropdown ${question.slug}: selectedId=$selectedId, answersValue=$answersValue");
      
      // If we have stale data in _answers that's a value instead of ID, try to find the correct ID
      if (selectedId == null && answersValue != null) {
        final matchingOption = question.options.firstWhere(
          (opt) => opt.value == answersValue.toString() || opt.id == answersValue.toString(),
          orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
        );
        if (matchingOption.id.isNotEmpty) {
          _selected[question.slug] = matchingOption.id;
          debugPrint("🔄 Fixed dropdown mapping for ${question.slug}: $answersValue -> ${matchingOption.id}");
          needsUpdate = true;
        } else {
          _answers.remove(question.slug);
          _responses.removeWhere((r) => r['question_id'] == question.id);
          debugPrint("🗑️ Cleared invalid dropdown value for ${question.slug}: $answersValue");
          needsUpdate = true;
        }
      }
      
      // Check if the selected ID still exists in current options
      if (selectedId != null) {
        final optionExists = question.options.any((opt) => opt.id == selectedId);
        if (!optionExists) {
          _selected.remove(question.slug);
          _answers.remove(question.slug);
          _responses.removeWhere((r) => r['question_id'] == question.id);
          debugPrint("🗑️ Cleared invalid dropdown selection for ${question.slug}: $selectedId");
          needsUpdate = true;
        }
      }
    }
    
    if (needsUpdate) {
      setState(() {
        _isFormValid = _validateForm();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading && userId != null && token != null) {
      _fetchCurrentStepQuestions();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && userId != null && token != null) {
      _fetchCurrentStepQuestions();
    }
  }

  void _fetchCurrentStepQuestions() {
    if (_bloc != null) {
      _bloc.add(
        FetchOnboardingQuestions(
          userId: userId!,
          screenSlug: _currentStep.toString(),
          token: token!,
        ),
      );
    }
  }

  Future<void> _initBloc() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    token = sharedPrefs.getString(AppConstants.accessTokenKey);
    appLanguageCode = await prefHelper.getAppLanguage();
    userId = await secureStorage.getUserId();

    if (userId == null || userId!.isEmpty || token == null) {
      setState(() => _loading = false);
      return;
    }

    final apiBase = ApiBase();
    final dataSource = OnboardingRemoteDataSource(apiBase);
    final repository = OnboardingRepositoryImpl(dataSource);

    _bloc = OnboardingBloc(repository)
      ..add(
        FetchOnboardingQuestions(
          userId: userId!,
          screenSlug: _currentStep.toString(),
          token: token!,
        ),
      );

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    _questions.clear();
    _selected.clear();
    _answers.clear();
    _responses.clear();
    _isFormValid = false;
    _requiredQuestionCount = 0;
    super.dispose();
  }

  void _selectOption(String slug, String optionId, String optionText, String questionId) {
    setState(() {
      _selected[slug] = optionId;
      
      // Store the option value (not ID) in _answers for visibility condition evaluation
      final question = _questions.firstWhere((q) => q.slug == slug);
      final selectedOption = question.options.firstWhere((o) => o.id == optionId);
      _answers[slug] = selectedOption.value; // Store "yes"/"no" instead of option ID
      
      _responses.removeWhere((r) => r['question_id'] == questionId);
      _responses.add({
        "question_id": questionId,
        "option_id": optionId,
        "value": optionText,
      });
      _isFormValid = _validateForm();
    });
    
    debugPrint("🎯 Selected option for $slug: ID=$optionId, Value=${_answers[slug]}, Text=$optionText");
  }

  void _updateValue(String slug, String questionId, dynamic value) {
    setState(() {
      _answers[slug] = value;
      _selected.remove(slug);
      _responses.removeWhere((r) => r['question_id'] == questionId);
      if (value is List<dynamic>) {
        for (var id in value) {
          final opt = _questions
              .firstWhere((q) => q.id == questionId)
              .options
              .firstWhere(
                (o) => o.id == id,
                orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
              );
          if (opt.id.isNotEmpty) {
            _responses.add({
              "question_id": questionId,
              "option_id": id,
              "value": opt.text,
            });
          }
        }
      } else {
        _responses.add({"question_id": questionId, "value": value});
      }
      _isFormValid = _validateForm();
    });
  }

  bool _validateForm() {
    // Only validate visible questions
    final visibleQuestions = _questions.where((q) => 
      evaluateVisibility(q.visibilityConditions, _answers)
    ).toList();
    
    debugPrint("🔍 Validating form with ${_responses.length} responses for ${visibleQuestions.length} visible questions (${_questions.length} total)");
    
    // Group questions by validation rules
    final exclusiveQuestions = <OnboardingQuestionEntity>[];
    final excludedBySomeExclusive = <String>{};
    final normalQuestions = <OnboardingQuestionEntity>[];
    
    for (var q in visibleQuestions) {
      if (q.validationRules?['rule'] == 'exclusive') {
        exclusiveQuestions.add(q);
        final excludes = q.validationRules?['excludes'] as List<dynamic>?;
        if (excludes != null) {
          for (var excludedSlug in excludes) {
            if (excludedSlug is String) {
              excludedBySomeExclusive.add(excludedSlug);
            }
          }
        }
      } else {
        normalQuestions.add(q);
      }
    }
    
    debugPrint("🔍 Exclusive questions: ${exclusiveQuestions.map((q) => q.slug).toList()}");
    debugPrint("🔍 Excluded by exclusive: $excludedBySomeExclusive");
    debugPrint("🔍 Normal questions: ${normalQuestions.map((q) => q.slug).toList()}");
    
    // Check if any exclusive question is answered
    bool hasExclusiveAnswer = false;
    for (var exclusiveQ in exclusiveQuestions) {
      final responses = _responses.where((r) => r["question_id"] == exclusiveQ.id).toList();
      if (responses.isNotEmpty && _hasValidResponse(exclusiveQ, responses)) {
        hasExclusiveAnswer = true;
        debugPrint("✅ Exclusive question ${exclusiveQ.slug} has valid answer");
        break;
      }
    }
    
    if (hasExclusiveAnswer) {
      // If exclusive answer exists, only validate the exclusive question that's answered
      debugPrint("✅ Form valid - exclusive question answered, others cleared");
      return true;
    }
    
    // Otherwise, validate all required non-exclusive questions
    for (var q in visibleQuestions) {
      if (q.isRequired && q.validationRules?['rule'] != 'exclusive') {
        final responses = _responses.where((r) => r["question_id"] == q.id).toList();
        debugPrint("Question ${q.slug} (required: ${q.isRequired}, visible: true): ${responses.length} responses");

        if (responses.isEmpty) {
          debugPrint("❌ Missing response for required question: ${q.slug}");
          return false;
        }
        if (!_hasValidResponse(q, responses)) {
          debugPrint("❌ Invalid response for required question: ${q.slug}");
          return false;
        }
      }
    }
    
    debugPrint("✅ Form validation passed");
    return true;
  }
  
  // Helper method to check if a question has a valid response
  bool _hasValidResponse(OnboardingQuestionEntity question, List<Map<String, dynamic>> responses) {
    if (question.inputType == 'checkbox' || question.inputType == 'multi_choice') {
      return responses.isNotEmpty && 
             responses.any((r) => r['value'] != null && r['value'].toString().isNotEmpty);
    } else {
      final response = responses.first;
      final value = response["value"];
      return value != null && (value is! String || value.trim().isNotEmpty);
    }
  }

  void _handleNext() async {
    final currentUserId = await secureStorage.getUserId();
    if (currentUserId == null || currentUserId.isEmpty) return;

    if (_isFormValid) {
      final Map<String, dynamic> payload = {
        "responses": _responses
            .map((r) => {
                  "question_id": r["question_id"].toString(),
                  if (r.containsKey("option_id") && r["option_id"] != null)
                    "option_id": r["option_id"].toString(),
                  "value": r["value"],
                })
            .toList(),
      };

      debugPrint("Submitting payload JSON: ${jsonEncode(payload)}");

      _bloc.add(
        SubmitOnboardingAnswers(
          userId: currentUserId,
          screenSlug: _currentStep.toString(),
          token: token!,
          answers: payload,
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please answer all required questions")),
        );
      }
    }
  }

  void _handleSkip() {
    final totalSteps = _screen['totalSteps'] ?? 7;
    debugPrint('🚀 Skip clicked - Current step: $_currentStep, Total steps: $totalSteps');
    
    if (_currentStep < totalSteps) {
      debugPrint('🚀 Moving to next step: ${_currentStep + 1}');
      
      // Clear current form data first
      _selected.clear();
      _answers.clear();
      _responses.clear();
      _isFormValid = false;
      
      // Update current step
      _currentStep++;
      
      // Trigger BLoC event to fetch new screen content
      if (_bloc != null && token != null) {
        _bloc.add(
          FetchOnboardingQuestions(
            userId: userId!,
            screenSlug: _currentStep.toString(),
            token: token!,
          ),
        );
      }
    } else {
      debugPrint('🚀 On last step, completing onboarding');
      // If on last step, go to dashboard
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.dashboardHome,
          (route) => false,
        );
        Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence);
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _isFormValid = false;
        _selected.clear();
        _answers.clear();
        _responses.clear();
      });
      _fetchCurrentStepQuestions();
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: const [
          InputSkeleton(),
          OptionTileSkeleton(),
          QuestionSkeleton(numOptions: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || token == null || userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocProvider(
      create: (_) => _bloc,
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingSuccess) {
            _responses.clear();
            _answers.clear();
            _selected.clear();

            _screen = {
              'id': state.data.screenId,
              'slug': state.data.slug,
              'title': state.data.title,
              'subtitle': state.data.description ?? '',
              'buttonText': state.data.buttonText ?? 'Next',
              'totalSteps': state.data.totalSteps ?? 7
            };

            _questions = List.from(state.data.questions)
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            _requiredQuestionCount = _questions.where((q) => q.isRequired).length;

            final user = state.data.user;

            for (var q in _questions) {
              final String qId = q.id;
              final String qSlug = q.slug;

              dynamic prefilledValue;
              if (user != null && q.targetField != null) {
                prefilledValue = user[q.targetField];
              }
              if (prefilledValue == null && q.prefillValue != null) {
                prefilledValue = q.prefillValue;
              }
              
              debugPrint('🔍 Question ${q.slug} (${q.inputType}): prefillValue = $prefilledValue');
              if (q.inputType == "multi_choice") {
                debugPrint('  Available options:');
                for (var opt in q.options) {
                  debugPrint('    ${opt.text} (id: ${opt.id}, value: ${opt.value}, isSelected: ${opt.isSelected})');
                }
              }

              if (prefilledValue != null) {
                if (q.inputType == "single_choice" || q.inputType == "dropdown") {
                  final matchOpt = q.options.firstWhere(
                    (o) =>
                        o.text == prefilledValue.toString() ||
                        o.id == prefilledValue.toString() ||
                        o.value == prefilledValue.toString(),
                    orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                  );
                  if (matchOpt.id.isNotEmpty) {
                    _selected[qSlug] = matchOpt.id;
                    _answers[qSlug] = matchOpt.value; // Store the option value for visibility evaluation
                    _responses.add({
                      "question_id": qId,
                      "option_id": matchOpt.id,
                      "value": matchOpt.text,
                    });
                    debugPrint("🎯 Prefilled $qSlug: ID=${matchOpt.id}, Value=${matchOpt.value}");
                  }
                } else {
                  _answers[qSlug] = prefilledValue;
                  _responses.add({
                    "question_id": qId,
                    "value": prefilledValue.toString(),
                  });
                }
              }
              
              // Process is_selected flags from backend for multi-choice questions only
              if (q.inputType == "multi_choice" || q.inputType == "checkbox") {
                // Initialize as empty list if not already set, or reset if it's not a list
                if (_answers[qSlug] == null || _answers[qSlug] is! List<String>) {
                  _answers[qSlug] = <String>[];
                }
                
                final selectedOptions = q.options.where((o) => o.isSelected).toList();
                debugPrint('🔍 Processing is_selected for ${q.slug}: found ${selectedOptions.length} selected options');
                
                for (final opt in selectedOptions) {
                  debugPrint('  Adding selected option: ${opt.text} (${opt.id})');
                  final answersList = _answers[qSlug] as List<String>;
                  
                  // Only add if not already in the list
                  if (!answersList.contains(opt.id)) {
                    answersList.add(opt.id);
                  }
                  
                  // Only add to responses if not already present
                  bool alreadyInResponses = _responses.any((r) => 
                    r['question_id'] == qId && r['option_id'] == opt.id);
                  if (!alreadyInResponses) {
                    _responses.add({
                      "question_id": qId,
                      "option_id": opt.id,
                      "value": opt.text,
                    });
                  }
                }
              }
              
              // For single choice, process is_selected only if not already set by prefill_value
              if ((q.inputType == "single_choice" || q.inputType == "dropdown") && !_selected.containsKey(qSlug)) {
                final opt = q.options.firstWhere(
                  (o) => o.isSelected,
                  orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                );
                if (opt.id.isNotEmpty) {
                  _selected[qSlug] = opt.id;
                  _answers[qSlug] = opt.value; // Store the option value for visibility evaluation
                  _responses.add({
                    "question_id": qId,
                    "option_id": opt.id,
                    "value": opt.text,
                  });
                  debugPrint("🎯 Pre-selected $qSlug: ID=${opt.id}, Value=${opt.value}");
                }
              }
            }

            debugPrint("🎯 After processing prefills: ${_responses.length} responses for ${_questions.length} questions");
            for (var response in _responses) {
              debugPrint("Response: ${response['question_id']} -> ${response['value']}");
            }
            
            debugPrint("📋 _answers map contents:");
            for (var entry in _answers.entries) {
              debugPrint("  ${entry.key}: ${entry.value} (${entry.value.runtimeType})");
            }

            // Fix all dropdown values and clear invalid ones
            _fixDropdownValues();

            // Clear responses for invisible questions after processing prefills
            _clearInvisibleQuestionResponses();
            
            setState(() {
              _isFormValid = _validateForm();
            });
          } else if (state is OnboardingAnswersSubmitted) {
            final prevIndex = _currentStep;
            if (prevIndex + 1 <= _screen['totalSteps']) {
              _currentStep = prevIndex + 1;
              _selected.clear();
              _answers.clear();
              _responses.clear();
              _isFormValid = false;
              _fetchCurrentStepQuestions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data saved successfully!'),
                  duration: Duration(milliseconds: 1300),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.dashboardHome,
                  (route) => false,
                );

                Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence);

                debugPrint("✅ Onboarding completed!");
              }

              debugPrint("✅ Onboarding completed!");
            }
          } else if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          Widget content;
          if (state is OnboardingLoading) {
            content = _buildSkeleton();
          } else if (state is OnboardingError) {
            content = SomethingWentWrong();
          } else {
            // Filter questions based on visibility conditions
            final visibleQuestions = _questions.where((question) {
              return evaluateVisibility(question.visibilityConditions, _answers);
            }).toList();
            
            content = Column(
              spacing: 25,
              children: visibleQuestions.map((question) {
                final options = question.options
                    .map((o) {
                          final isSelected = _answers[question.slug] is List<dynamic>
                              ? (_answers[question.slug] as List<dynamic>).contains(o.id)
                              : question.inputType == "dropdown" 
                                ? _selected[question.slug] == o.id // For dropdowns, compare with selected ID
                                : _answers[question.slug] == o.value; // For other types, compare with value
                          
                          debugPrint('🔍 Option ${o.text} (${o.id}): isSelected = $isSelected, _answers[${question.slug}] = ${_answers[question.slug]}, inputType = ${question.inputType}');
                          
                          return OptionItem(
                            label: o.text,
                            id: o.id,
                            description: o.description?.toString(),
                            value: o.value,
                            isSelected: isSelected,
                          );
                        })
                    .toList();
                debugPrint("🥶🥶🥶🥶🥶 Prefill Value: ${question.prefillValue} for ${question.slug} and keyboard type is ${question.keyboardType}");
                debugPrint('✅ Current Step: $_currentStep, Question Type: ${question.inputType}, Options Per Row: ${_currentStep == 8 ? 2 : "default"}, Question: ${question.questionText}');
                return QuestionInputWidget(
                  id: question.id,
                  slug: question.slug,
                  title: question.questionText,
                  inputType: question.inputType,
                  keyboardType: question.keyboardType,
                  prefillValue: question.inputType == "dropdown" 
                    ? _getSafeDropdownValue(question)
                    : _answers[question.slug] ?? question.prefillValue,
                  options: options,
                  optionsPerRow: _currentStep == 7 ? 2 : null,
                  values: question.inputType == "dropdown" 
                    ? {
                        ...Map<String, dynamic>.from(_answers)
                          ..remove(question.slug), // Remove the dropdown entry
                        if (_getSafeDropdownValue(question) != null)
                          question.slug: _getSafeDropdownValue(question), // Add the safe ID
                      }
                    : _answers,
                  onValueChanged: (slug, value) {
                    final question = _questions.firstWhere((q) => q.slug == slug);
                    
                    // Handle regular value updates
                    if (question.inputType == "single_choice" || question.inputType == "dropdown") {
                      final selectedOption = question.options.firstWhere(
                        (o) => o.id == value,
                        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                      );
                      if (selectedOption.id.isNotEmpty) {
                        _selectOption(slug, selectedOption.id, selectedOption.text, question.id);
                        
                        // Apply validation rules for exclusivity
                        applyValidationRules(question, selectedOption.value, _answers, (updatedResponses) {
                          setState(() {
                            _answers.clear();
                            _answers.addAll(updatedResponses);
                            _isFormValid = _validateForm();
                          });
                        });
                        
                        // Handle reverse exclusivity - clear exclusive questions if this question is in their excludes list
                        _handleReverseExclusivity(slug);
                        
                        // Trigger rebuild to re-evaluate visibility conditions
                        setState(() {
                          _isFormValid = _validateForm();
                        });
                      }
                    } else if (question.inputType == "multi_choice" || question.inputType == "checkbox") {
                      if (value is List<dynamic>) {
                        _updateValue(slug, question.id, value);
                        
                        // For multi-choice, apply validation rules for each selected value
                        if (value.isNotEmpty) {
                          applyValidationRules(question, value, _answers, (updatedResponses) {
                            setState(() {
                              _answers.clear();
                              _answers.addAll(updatedResponses);
                            });
                          });
                          
                          // Handle reverse exclusivity for multi-choice
                          _handleReverseExclusivity(slug);
                        }
                      }
                    } else {
                      _updateValue(slug, question.id, value);
                      
                      // Apply validation rules for text/other inputs
                      applyValidationRules(question, value, _answers, (updatedResponses) {
                        setState(() {
                          _answers.clear();
                          _answers.addAll(updatedResponses);
                        });
                      });
                      
                      // Handle reverse exclusivity for text inputs
                      _handleReverseExclusivity(slug);
                    }
                    
                    // Clear responses for questions that are no longer visible
                    _clearInvisibleQuestionResponses();
                    
                    // Fix any dropdown value issues after visibility changes
                    _fixDropdownValues();
                  },
                );
              }).toList(),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(
                context,
              ).unfocus(); // 🔑 dismiss keyboard + unfocus input
            },
            child: BaseQuestionPage(
              currentStep: _currentStep,
              onSkip: _handleSkip,
              totalSteps: 7,
              title: _screen['title'] ?? 'Tell us about your lifestyle',
              subtitle:
                  _screen['subtitle'] ??
                  'Your lifestyle helps us analyze your skin.',
              buttonText: _screen['buttonText'] ?? 'Next',
            isFormValid: _isFormValid,
            onNext: _handleNext,
            showBackButton: _currentStep > 1,
            onBack: _handleBack,
            content: content,
          ),
          );
        },
      ),
    );
  }
}