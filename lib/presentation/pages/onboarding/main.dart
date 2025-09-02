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
      _answers[slug] = optionId;
      _responses.removeWhere((r) => r['question_id'] == questionId);
      _responses.add({
        "question_id": questionId,
        "option_id": optionId,
        "value": optionText,
      });
      _isFormValid = _validateForm();
    });
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
    debugPrint("🔍 Validating form with ${_responses.length} responses for ${_questions.length} questions");
    for (var q in _questions) {
      final responses = _responses.where((r) => r["question_id"] == q.id).toList();
      debugPrint("Question ${q.slug} (required: ${q.isRequired}): ${responses.length} responses");

      if (q.isRequired) {
        if (responses.isEmpty) {
          debugPrint("❌ Missing response for required question: ${q.slug}");
          return false;
        }
        if (q.inputType == 'checkbox' || q.inputType == 'multi_choice') {
          if (responses.isEmpty || responses.every((r) => r['value'] == null || r['value'].toString().isEmpty)) {
            debugPrint("❌ No valid selections for required checkbox/multi_choice question: ${q.slug}");
            return false;
          }
        } else {
          final response = responses.first;
          final value = response["value"];
          if (value == null || (value is String && value.trim().isEmpty)) {
            debugPrint("❌ Invalid value for required question: ${q.slug}");
            return false;
          }
        }
      }
    }
    debugPrint("✅ Form validation passed");
    return true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all required questions")),
      );
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
              'totalSteps': state.data.totalSteps ?? 8
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

              if (prefilledValue != null) {
                if (q.inputType == "multi_choice" || q.inputType == "checkbox") {
                  _answers[qSlug] = <String>[];
                  if (prefilledValue is List<dynamic>) {
                    for (final val in prefilledValue) {
                      final matchOpt = q.options.firstWhere(
                        (o) =>
                            o.text == val.toString() ||
                            o.id == val.toString() ||
                            o.value == val.toString(),
                        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                      );
                      if (matchOpt.id.isNotEmpty) {
                        (_answers[qSlug] as List<String>).add(matchOpt.id);
                        _responses.add({
                          "question_id": qId,
                          "option_id": matchOpt.id,
                          "value": matchOpt.text,
                        });
                      }
                    }
                  } else if (prefilledValue is String) {
                    final matchOpt = q.options.firstWhere(
                      (o) =>
                          o.text == prefilledValue ||
                          o.id == prefilledValue ||
                          o.value == prefilledValue,
                      orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                    );
                    if (matchOpt.id.isNotEmpty) {
                      (_answers[qSlug] as List<String>).add(matchOpt.id);
                      _responses.add({
                        "question_id": qId,
                        "option_id": matchOpt.id,
                        "value": matchOpt.text,
                      });
                    }
                  }
                } else if (q.inputType == "single_choice" || q.inputType == "dropdown") {
                  final matchOpt = q.options.firstWhere(
                    (o) =>
                        o.text == prefilledValue.toString() ||
                        o.id == prefilledValue.toString() ||
                        o.value == prefilledValue.toString(),
                    orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                  );
                  if (matchOpt.id.isNotEmpty) {
                    _selected[qSlug] = matchOpt.id;
                    _answers[qSlug] = matchOpt.id;
                    _responses.add({
                      "question_id": qId,
                      "option_id": matchOpt.id,
                      "value": matchOpt.text,
                    });
                  }
                } else {
                  _answers[qSlug] = prefilledValue;
                  _responses.add({
                    "question_id": qId,
                    "value": prefilledValue.toString(),
                  });
                }
              } else {
                if (q.inputType == "multi_choice" || q.inputType == "checkbox") {
                  _answers[qSlug] = <String>[];
                  final selectedOptions = q.options.where((o) => o.isSelected).toList();
                  for (final opt in selectedOptions) {
                    (_answers[qSlug] as List<String>).add(opt.id);
                    _responses.add({
                      "question_id": qId,
                      "option_id": opt.id,
                      "value": opt.text,
                    });
                  }
                } else {
                  final opt = q.options.firstWhere(
                    (o) => o.isSelected,
                    orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                  );
                  if (opt.id.isNotEmpty) {
                    _selected[qSlug] = opt.id;
                    _answers[qSlug] = opt.id;
                    _responses.add({
                      "question_id": qId,
                      "option_id": opt.id,
                      "value": opt.text,
                    });
                  }
                }
              }
            }

            debugPrint("🎯 After processing prefills: ${_responses.length} responses for ${_questions.length} questions");
            for (var response in _responses) {
              debugPrint("Response: ${response['question_id']} -> ${response['value']}");
            }

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
            content = Column(
              spacing: 25,
              children: _questions.map((question) {
                final options = question.options
                    .map((o) => OptionItem(
                          label: o.text,
                          id: o.id,
                          description: o.description?.toString(),
                          value: o.value,
                          isSelected: _answers[question.slug] is List<dynamic>
                              ? (_answers[question.slug] as List<dynamic>).contains(o.id)
                              : _answers[question.slug] == o.id,
                        ))
                    .toList();
                debugPrint("🥶🥶🥶🥶🥶 Prefill Value: ${question.prefillValue} for ${question.slug} and keyboard type is ${question.keyboardType}");
                return QuestionInputWidget(
                  id: question.id,
                  slug: question.slug,
                  title: question.questionText,
                  inputType: question.inputType,
                  keyboardType: question.keyboardType,
                  prefillValue: _answers[question.slug] ?? question.prefillValue,
                  options: options,
                  values: _answers,
                  onValueChanged: (slug, value) {
                    final question = _questions.firstWhere((q) => q.slug == slug);
                    if (question.inputType == "single_choice" || question.inputType == "dropdown") {
                      final selectedOption = question.options.firstWhere(
                        (o) => o.id == value,
                        orElse: () => OnboardingOptionEntity(id: '', text: '', value: ''),
                      );
                      if (selectedOption.id.isNotEmpty) {
                        _selectOption(slug, selectedOption.id, selectedOption.text, question.id);
                      }
                    } else if (question.inputType == "multi_choice" || question.inputType == "checkbox") {
                      if (value is List<dynamic>) {
                        _updateValue(slug, question.id, value);
                      }
                    } else {
                      _updateValue(slug, question.id, value);
                    }
                  },
                );
              }).toList(),
            );
          }

          return BaseQuestionPage(
            currentStep: _currentStep,
            totalSteps: 8,
            title: _screen['title'] ?? 'Tell us about your lifestyle',
            subtitle: _screen['subtitle'] ?? 'Your lifestyle helps us analyze your skin.',
            buttonText: _screen['buttonText'] ?? 'Next',
            isFormValid: _isFormValid,
            onNext: _handleNext,
            showBackButton: _currentStep > 1,
            onBack: _handleBack,
            content: content,
          );
        },
      ),
    );
  }
}