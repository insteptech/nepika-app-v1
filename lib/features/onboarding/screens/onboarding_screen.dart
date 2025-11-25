import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import 'package:nepika/core/widgets/base_question_page.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/onboarding/datasources/onboarding_remote_datasource.dart';
import 'package:nepika/data/onboarding/repositories/onboarding_repository.dart';
import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_event.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_state.dart';
import 'package:nepika/features/onboarding/components/question_input.dart';
import 'package:nepika/features/onboarding/utils/onboarding_validator.dart';
import 'package:nepika/features/onboarding/utils/visibility_evaluator.dart';
import 'package:nepika/features/onboarding/widgets/onboarding_skeleton.dart';
import 'package:nepika/features/onboarding/widgets/onboarding_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final int? initialStep;
  final VoidCallback? customOnBack;
  final bool? customShowSkip;
  final bool? showProgressBar;
  final bool? isFromSettingNavigation;
  final String? mainButtonText;

  const OnboardingScreen({
    super.key,
    this.initialStep,
    this.customOnBack,
    this.customShowSkip,
    this.showProgressBar,
    this.isFromSettingNavigation = false,
    this.mainButtonText,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late OnboardingBloc _bloc;
  String? _userId;
  String? _token;
  bool _loading = true;
  late int _currentStep;

  // Track data state for smart button behavior
  int? _lastLoadedStep;

  // Track submission state to keep form visible
  bool _isSubmitting = false;
  OnboardingStepLoaded? _lastLoadedState;

  final _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentStep =
        widget.initialStep ?? 1; // Use custom initial step or default to 1
    _initializeBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading && _userId != null && _token != null) {
      _loadCurrentStep();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_loading &&
        _userId != null &&
        _token != null) {
      _loadCurrentStep();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  Future<void> _initializeBloc() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      _token = sharedPrefs.getString(AppConstants.accessTokenKey);
      _userId = await _secureStorage.getUserId();

      if (_userId == null || _userId!.isEmpty || _token == null) {
        setState(() => _loading = false);
        return;
      }

      // Initialize dependencies
      final apiBase = ApiBase();
      final dataSource = OnboardingRemoteDataSource(apiBase);
      final repository = OnboardingRepositoryImpl(dataSource);
      final validator = OnboardingValidator();
      final visibilityEvaluator = VisibilityEvaluator();

      _bloc = OnboardingBloc(
        repository: repository,
        validator: validator,
        visibilityEvaluator: visibilityEvaluator,
      );

      _loadCurrentStep();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error initializing onboarding: $e');
    }
  }

  void _loadCurrentStep() {
    if (_bloc.isClosed) {
      debugPrint('❌ Bloc is closed, cannot load step');
      return;
    }

    debugPrint('🔄 _loadCurrentStep called');
    debugPrint('🔄 Loading step: $_currentStep (screenSlug: ${_currentStep.toString()})');
    debugPrint('🔄 UserId: $_userId, Token: ${_token != null ? 'present' : 'null'}');
    
    _bloc.add(
      LoadOnboardingStep(
        userId: _userId!,
        screenSlug: _currentStep.toString(),
        token: _token!,
      ),
    );
    
    debugPrint('🔄 LoadOnboardingStep event dispatched');
  }

  void _handleNext() {
    // If coming from settings navigation, use the update-only function
    if (widget.isFromSettingNavigation == true) {
      _handleSettingsUpdate();
      return;
    }

    // Check if this is a skip action (prefilled data with no changes)
    // if (_hasPrefilledData && !_hasUserMadeChanges) {
    //   debugPrint('⏭️ Skipping step - no changes made to prefilled data');
    //   _moveToNextStep();
    //   return;
    // }

    // Otherwise, submit the step for normal onboarding flow
    debugPrint('📤 Submitting step data');
    _bloc.add(
      SubmitCurrentStep(
        userId: _userId!,
        screenSlug: _currentStep.toString(),
        token: _token!,
      ),
    );
  }

  void _handleSettingsUpdate() {
    debugPrint('🔧 Settings update - submitting data and will pop on success');

    // Submit the current step data
    _bloc.add(
      SubmitCurrentStep(
        userId: _userId!,
        screenSlug: _currentStep.toString(),
        token: _token!,
      ),
    );

    // Note: The actual pop happens in _handleBlocStateChanges when OnboardingStepSubmitted is received
    // This ensures we only pop after successful submission
  }

  void _handleSkip() {
    debugPrint('⏭️ Skipping step $_currentStep');

    // Get total steps from current state
    final currentState = _bloc.state;
    int totalSteps = 7; // Default fallback
    if (currentState is OnboardingStepLoaded) {
      totalSteps = currentState.screenData.totalSteps ?? 7;
    }

    // Check if we're at the last step
    if (_currentStep >= totalSteps) {
      debugPrint('🏁 Already at last step, completing onboarding');
      _navigateToCompletion();
      return;
    }

    // Increment step and load next step (same logic for both settings and normal flow)
    setState(() {
      _currentStep++;
    });
    debugPrint('⬆️ Skipped to step: $_currentStep');
    _loadCurrentStep();
  }

  void _handleBack() {
    // If navigating from settings, use settings-specific behavior
    // if (widget.isFromSettingNavigation != true) {
    //   if (_currentStep > 1) {
    //     setState(() {
    //       _currentStep--;
    //     });
    //     _loadCurrentStep();
    //   } else {
    //     Navigator.of(context).pop();
    //   }
    //   return;
    // }

    // If custom onBack is provided, use it instead of default behavior
    if (widget.customOnBack != null && widget.isFromSettingNavigation == true) {
      widget.customOnBack!();
      return;
    }

    // Default behavior for normal onboarding
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _bloc.add(const NavigateToPreviousStep());
      _loadCurrentStep();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleValueChanged(String slug, dynamic value) {
    debugPrint('🎯 Value changed - Slug: $slug, Value: $value');
    _bloc.add(UpdateAnswer(questionSlug: slug, value: value));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _token == null || _userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (_) => _bloc,
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: _handleBlocStateChanges,
        builder: (context, state) => _buildScreen(context, state),
      ),
    );
  }

  void _handleBlocStateChanges(BuildContext context, OnboardingState state) {
    debugPrint('🔄 BLoC state changed: ${state.runtimeType}');
    if (state is OnboardingStepLoaded) {
      // Save the loaded state so we can display it during submission
      _lastLoadedState = state;

      // Track step changes for debugging
      if (_lastLoadedStep != state.currentStep) {
        _lastLoadedStep = state.currentStep;
        debugPrint('📊 New screen loaded - Step: ${state.currentStep}');
      }

      debugPrint('🔘 Button text: ${_getButtonText()}');
      setState(() {
        _isSubmitting = false;
      });
    } else if (state is OnboardingStepSubmitting) {
      // Mark as submitting when submission starts
      setState(() {
        _isSubmitting = true;
      });
    } else if (state is OnboardingStepSubmitted) {
      debugPrint('✅ Step submitted successfully: ${state.message}');
      debugPrint('✅ NextStep from backend: ${state.nextStep}');
      debugPrint('✅ isFromSettingNavigation: ${widget.isFromSettingNavigation}');

      if (widget.isFromSettingNavigation == true) {
        debugPrint('🔧 Settings navigation - popping screen');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        debugPrint('📱 Normal onboarding flow - showing snackbar and moving to next step');
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(milliseconds: 1300),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            debugPrint('❌ Error showing success snackbar: $e');
          }
        }
        debugPrint('🚀 About to call _moveToNextStep()');
        _moveToNextStep();
      }
    } else if (state is OnboardingCompleted) {
      debugPrint('🏁 Onboarding completed via BLoC');
      if (widget.isFromSettingNavigation == true) {
        debugPrint('🔧 Settings navigation - popping screen');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _navigateToCompletion();
      }
    } else if (state is OnboardingError) {
      debugPrint('========================================');
      debugPrint('ERROR DETECTED IN ONBOARDING');
      debugPrint('❌ Onboarding error: ${state.message}');
      debugPrint('========================================');

      // Use post-frame callback to ensure widget is fully built before showing snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            debugPrint('✅ Error snackbar shown successfully');

            // Restore the form state so user can retry
            // This transitions back from error state to loaded state
            if (_lastLoadedState != null) {
              debugPrint('🔄 Dispatching RestoreFormState event');
              _bloc.add(RestoreFormState(state: _lastLoadedState!));
            }
          } catch (e) {
            debugPrint('❌ Error showing error snackbar: $e');
          }
        }
      });

      // Force rebuild to show error state without losing data
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _moveToNextStep() {
    final currentState = _bloc.state;
    debugPrint(
      '🚀 _moveToNextStep called. Current step: $_currentStep, State: ${currentState.runtimeType}',
    );

    if (currentState is OnboardingStepSubmitted) {
      final nextStep = currentState.nextStep;
      debugPrint('📈 Backend provided nextStep: $nextStep');
      debugPrint('📈 Current step before update: $_currentStep');

      if (nextStep != null && nextStep > 0) {
        // Use backend provided nextStep if valid
        setState(() {
          _currentStep = nextStep;
        });
        debugPrint('✅ Using backend nextStep: $_currentStep');
      } else {
        // Fallback: increment current step
        setState(() {
          _currentStep++;
        });
        debugPrint('⚠️ Backend nextStep invalid ($nextStep), incremented to: $_currentStep');
      }

      debugPrint('⬆️ Loading next step: $_currentStep');
      _loadCurrentStep();
    } else if (currentState is OnboardingStepLoaded) {
      // Direct skip case (no submission)
      final totalSteps = currentState.screenData.totalSteps ?? 7;
      debugPrint('📊 Total steps: $totalSteps, Current step: $_currentStep');
      
      if (_currentStep < totalSteps) {
        setState(() {
          _currentStep++;
        });
        debugPrint('⏭️ Skipped to step: $_currentStep');
        _loadCurrentStep();
      } else {
        debugPrint('🏁 Onboarding completed via skip');
        _navigateToCompletion();
      }
    } else {
      debugPrint(
        '⚠️ Unexpected state in _moveToNextStep: ${currentState.runtimeType}',
      );
      // Emergency fallback: try to increment step anyway
      debugPrint('🆘 Emergency fallback: incrementing step');
      setState(() {
        _currentStep++;
      });
      _loadCurrentStep();
    }
  }

  void _navigateToCompletion() {
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboardHome, (route) => false);
      Navigator.of(context).pushNamed(AppRoutes.faceScanOnboarding);
    }
  }

  String _getButtonText() {
    debugPrint(
      '🔘 _getButtonText called - isFromSettings: ${widget.isFromSettingNavigation}',
    );

    // If navigating from settings, always use "Update"
    if (widget.isFromSettingNavigation == true) {
      debugPrint('🔘 From settings - returning "Update"');
      return widget.mainButtonText ?? 'Update';
    }

    // For normal onboarding flow
    final currentState = _bloc.state;
    if (currentState is OnboardingStepLoaded) {
      final totalSteps = currentState.screenData.totalSteps ?? 7;
      if (_currentStep >= totalSteps) {
        debugPrint('🔘 Last step - returning "Complete"');
        return 'Complete';
      }
    }

    debugPrint('🔘 Normal flow - returning "Next"');
    return 'Next';
  }

  Widget _buildScreen(BuildContext context, OnboardingState state) {
    Widget content;
    String title = 'Tell us about yourself';
    String subtitle = 'Your answers will help us personalize your experience.';
    String buttonText = _getButtonText();
    bool isFormValid = false;
    int totalSteps = 7;

    if (state is OnboardingLoading) {
      // Only show skeleton when initially loading
      content = const OnboardingSkeleton();
    } else if (state is OnboardingStepSubmitting) {
      // Keep the form visible during submission using last loaded state
      if (_lastLoadedState != null) {
        title = _lastLoadedState!.screenData.title;
        subtitle = _lastLoadedState!.screenData.description ?? subtitle;
        buttonText = _getButtonText();
        isFormValid = _lastLoadedState!.isFormValid;
        totalSteps = _lastLoadedState!.screenData.totalSteps ?? totalSteps;
        content = _buildQuestionsList(_lastLoadedState!);
      } else {
        content = const OnboardingSkeleton();
      }
    } else if (state is OnboardingError) {
      // Don't show error widget in content, errors are shown via snackbar only
      // Keep the form visible using last loaded state so user can retry
      if (_lastLoadedState != null) {
        title = _lastLoadedState!.screenData.title;
        subtitle = _lastLoadedState!.screenData.description ?? subtitle;
        buttonText = _getButtonText();
        isFormValid = _lastLoadedState!.isFormValid;
        totalSteps = _lastLoadedState!.screenData.totalSteps ?? totalSteps;
        content = _buildQuestionsList(_lastLoadedState!);
      } else {
        content = const Center(
          child: Text('Please refresh to reload the form.'),
        );
      }
    } else if (state is OnboardingStepLoaded) {
      title = state.screenData.title;
      subtitle = state.screenData.description ?? subtitle;
      // Use smart button text instead of backend button text
      buttonText = _getButtonText();
      isFormValid = state.isFormValid;
      totalSteps = state.screenData.totalSteps ?? totalSteps;

      content = _buildQuestionsList(state);
    } else {
      content = const OnboardingSkeleton();
    }

    // Determine skip button visibility based on settings navigation
    bool shouldShowSkipButton = widget.isFromSettingNavigation == true
        ? false // Always hide when from settings
        : (_currentStep == 1
              ? false // Hide when step is 1
              : (widget.customShowSkip ??
                    true)); // Otherwise follow customShowSkip (default true)

    // Determine progress bar visibility based on settings navigation
    bool shouldShowProgressBar = widget.isFromSettingNavigation == true
        ? false // Hide progress bar when from settings
        : (widget.showProgressBar ??
              true); // Use existing logic for normal flow

    return BaseQuestionPage(
        currentStep: _currentStep,
        showSkipButton: shouldShowSkipButton,
        onSkip: _handleSkip,
        totalSteps: totalSteps,
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        isFormValid: isFormValid,
        onNext: _handleNext,
        showBackButton: _currentStep > 0,
        onBack: _handleBack,
        showProgressBar: shouldShowProgressBar,
        content: content,
        isLoading: _isSubmitting,
      );
  }

  Widget _buildQuestionsList(OnboardingStepLoaded state) {
    // Filter questions based on visibility conditions
    final visibleQuestions = state.screenData.questions.where((question) {
      final visibilityEvaluator = VisibilityEvaluator();
      return visibilityEvaluator.evaluateVisibility(
        question.visibilityConditions,
        state.answers,
      );
    }).toList();

    if (visibleQuestions.isEmpty) {
      return const Center(child: Text('No questions available for this step.'));
    }

    return Column(
      spacing: 25,
      children: visibleQuestions.map((question) {
        return QuestionInput(
          key: ValueKey('${question.slug}-${question.inputType}'),
          question: question,
          currentValue: _getCurrentValue(question, state),
          allAnswers: state.answers,
          onValueChanged: _handleValueChanged,
          optionsPerRow:  null,
        );
      }).toList(),
    );
  }

  dynamic _getCurrentValue(
    OnboardingQuestionEntity question,
    OnboardingStepLoaded state,
  ) {
    if (question.inputType == "dropdown") {
      return state.selectedOptions[question.slug];
    } else {
      return state.answers[question.slug];
    }
  }
}
