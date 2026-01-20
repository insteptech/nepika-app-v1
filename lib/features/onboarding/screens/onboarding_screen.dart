import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/di/injection_container.dart' as di;
import 'package:nepika/domain/auth/repositories/auth_repository.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import 'package:nepika/core/widgets/base_question_page.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/widgets/otp_input_field.dart';
import 'package:nepika/core/widgets/custom_button.dart';
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
import 'package:nepika/features/onboarding/screens/email_verification_screen.dart';
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
  bool _isEmailVerificationOpen = false;
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

      // Initialize OnboardingBloc with dependencies from Service Locator
      _bloc = OnboardingBloc(
        repository: repository,
        authRepository: di.ServiceLocator.get<AuthRepository>(),
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
    
    // Safety check: if Bloc is in error state or verification state without previous data, try to restore from UI backup
    if (_bloc.state is OnboardingError) {
      final errorState = _bloc.state as OnboardingError;
      if (errorState.previousState == null && _lastLoadedState != null) {
        debugPrint('🔄 Restoring lost form state from UI (Error) before submitting');
        _bloc.add(RestoreFormState(state: _lastLoadedState!));
      }
    } else if (_bloc.state is OnboardingEmailVerificationRequired) {
      final verifyState = _bloc.state as OnboardingEmailVerificationRequired;
      if (verifyState.previousState == null && _lastLoadedState != null) {
        debugPrint('🔄 Restoring lost form state from UI (Verify) before submitting');
        _bloc.add(RestoreFormState(state: _lastLoadedState!));
      }
    }

    // Small delay to ensure state restoration processes if needed? 
    // Bloc processes events sequentially, so adding Submit immediately after Restore should work.
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
      // On step 1, we can't go back further. Navigate to login screen instead of popping (which causes black screen).
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
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
    } else if (state is OnboardingEmailVerificationRequired) {
      debugPrint('📧 Email verification required');
      setState(() {
        _isSubmitting = false; // Stop spinner on main screen so we can navigate
      });
      _navigateToEmailVerification(state.email, state.otpId);
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
                duration: const Duration(seconds: 2),
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

      // If the error is specifically "Invalid OTP" (verification error on the OTP screen),
      // we handle it inline in the EmailVerificationScreen.
      // We do NOT skip rate limit errors (429) or other general OTP-related errors.
      if (state.message.contains('Invalid OTP')) {
        debugPrint('🚫 Skipping global snackbar for Invalid OTP error (handled inline on verification screen)');
        return;
      }

      // Use post-frame callback to ensure widget is fully built before showing snackbar
      // Capture messenger here to avoid 'deactivated widget' errors inside callback
      final messenger = ScaffoldMessenger.of(context);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                  },
                ),
              ),
            );
            debugPrint('✅ Error snackbar shown successfully');
            
            // Note: We do NOT restore form state here automatically anymore.
            // We stay in Error state so the user sees the error.
            // The Bloc's _onSubmitCurrentStep handles recovery from Error state using previousState.
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

  void _navigateToEmailVerification(String email, String otpId) async {
    // Prevent duplicate navigation if screen is already open
    if (_isEmailVerificationOpen) {
      debugPrint('🚫 Email verification screen already open - skipping duplicate navigation');
      return;
    }

    debugPrint('🚦 Navigating to Email Verification. _lastLoadedState answers count: ${_lastLoadedState?.answers.length}');
    debugPrint('🚦 _lastLoadedState answers: ${_lastLoadedState?.answers}');

    _isEmailVerificationOpen = true;

    // We wait for the result of the push to determine if we need to restore state upon return
    // (e.g. if user pressed back button without verifying)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(
          email: email,
          otpId: otpId,
          onboardingBloc: _bloc,
        ),
      ),
    );

    _isEmailVerificationOpen = false;

    // After returning from the screen:
    // Check if we are still in a state that requires restoration (e.g. VerifyRequired or Error)
    // and if we have a backup.
    // After returning from the screen:
    // Check if we are still in a state that requires restoration (e.g. VerifyRequired or Error)
    final currentState = _bloc.state;
    if (currentState is OnboardingEmailVerificationRequired || currentState is OnboardingError) {
       debugPrint('🔙 Email Screen dismissed without completion - restoring form state');
       
       OnboardingStepLoaded? stateToRestore;
       
       if (currentState is OnboardingEmailVerificationRequired) {
         stateToRestore = currentState.previousState;
       } else if (currentState is OnboardingError) {
         stateToRestore = currentState.previousState;
       }
       
       // Fallback to _lastLoadedState if previousState is null
       stateToRestore ??= _lastLoadedState;
       
       if (stateToRestore != null) {
         debugPrint('🔄 Restoring state from backup');
         _bloc.add(RestoreFormState(state: stateToRestore));
       } else {
         debugPrint('⚠️ No state to restore!');
       }
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
    } else if (state is OnboardingStepSubmitting || state is OnboardingEmailVerificationRequired) {
      // Keep the form visible during submission/verification using last loaded state
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
