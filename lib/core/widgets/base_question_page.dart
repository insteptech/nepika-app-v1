import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import 'question_header.dart';
import 'custom_button.dart';

class QuestionPageData {
  final String? name;
  final String? email;
  final String? gender;
  final String? dateOfBirth;
  final String? height;
  final String? weight;
  final String? waistSize;
  final String? jobType;
  final String? workEnvironment;
  final String? stressLevel;
  final String? activityLevel;
  final String? hydrationLevel;
  final String? skinType;
  final bool? doesMenstruate;
  final String? currentPhase;
  final String? cycleRegularity;
  final Set<String>? pmsSymptoms;
  final String? startDate;
  final String? cycleLength;
  final String? currentDay;
  final String? menopauseStatus;
  final String? lastPeriodDate;
  final Set<String>? menopauseSymptoms;
  final bool? usesHRT;
  final Set<String>? skinGoals;
  final Map<String, dynamic>? faceScanResults;

  const QuestionPageData({
    this.name,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.waistSize,
    this.jobType,
    this.workEnvironment,
    this.stressLevel,
    this.activityLevel,
    this.hydrationLevel,
    this.skinType,
    this.doesMenstruate,
    this.currentPhase,
    this.cycleRegularity,
    this.pmsSymptoms,
    this.startDate,
    this.cycleLength,
    this.currentDay,
    this.menopauseStatus,
    this.lastPeriodDate,
    this.menopauseSymptoms,
    this.usesHRT,
    this.skinGoals,
    this.faceScanResults,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'height': height,
      'weight': weight,
      'waistSize': waistSize,
      'jobType': jobType,
      'workEnvironment': workEnvironment,
      'stressLevel': stressLevel,
      'activityLevel': activityLevel,
      'hydrationLevel': hydrationLevel,
      'skinType': skinType,
      'doesMenstruate': doesMenstruate,
      'currentPhase': currentPhase,
      'cycleRegularity': cycleRegularity,
      'pmsSymptoms': pmsSymptoms?.toList(),
      'startDate': startDate,
      'cycleLength': cycleLength,
      'currentDay': currentDay,
      'menopauseStatus': menopauseStatus,
      'lastPeriodDate': lastPeriodDate,
      'menopauseSymptoms': menopauseSymptoms?.toList(),
      'usesHRT': usesHRT,
      'skinGoals': skinGoals?.toList(),
      'faceScanResults': faceScanResults,
    };
  }

  QuestionPageData copyWith({
    String? name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? height,
    String? weight,
    String? waistSize,
    String? jobType,
    String? workEnvironment,
    String? stressLevel,
    String? activityLevel,
    String? hydrationLevel,
    String? skinType,
    bool? doesMenstruate,
    String? currentPhase,
    String? cycleRegularity,
    Set<String>? pmsSymptoms,
    String? startDate,
    String? cycleLength,
    String? currentDay,
    String? menopauseStatus,
    String? lastPeriodDate,
    Set<String>? menopauseSymptoms,
    bool? usesHRT,
    Set<String>? skinGoals,
    Map<String, dynamic>? faceScanResults,
  }) {
    return QuestionPageData(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      waistSize: waistSize ?? this.waistSize,
      jobType: jobType ?? this.jobType,
      workEnvironment: workEnvironment ?? this.workEnvironment,
      stressLevel: stressLevel ?? this.stressLevel,
      activityLevel: activityLevel ?? this.activityLevel,
      hydrationLevel: hydrationLevel ?? this.hydrationLevel,
      skinType: skinType ?? this.skinType,
      doesMenstruate: doesMenstruate ?? this.doesMenstruate,
      currentPhase: currentPhase ?? this.currentPhase,
      cycleRegularity: cycleRegularity ?? this.cycleRegularity,
      pmsSymptoms: pmsSymptoms ?? this.pmsSymptoms,
      startDate: startDate ?? this.startDate,
      cycleLength: cycleLength ?? this.cycleLength,
      currentDay: currentDay ?? this.currentDay,
      menopauseStatus: menopauseStatus ?? this.menopauseStatus,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      menopauseSymptoms: menopauseSymptoms ?? this.menopauseSymptoms,
      usesHRT: usesHRT ?? this.usesHRT,
      skinGoals: skinGoals ?? this.skinGoals,
      faceScanResults: faceScanResults ?? this.faceScanResults,
    );
  }
}

class BaseQuestionPage extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget content;
  final String buttonText;
  final bool isFormValid;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showBackButton;
  final bool showSkipButton;

  // Universal list of question routes (update as needed)
  static final List<String> questionRoutes = [
    '/userDetails',
    '/userInfo',
    '/skinGoals',
    '/skinType',
    '/menstrualCycle',
    '/faceScan',
  ];

  const BaseQuestionPage({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.buttonText,
    required this.isFormValid,
    this.onNext,
    this.onBack,
    this.onSkip,
    this.showBackButton = true,
    this.showSkipButton = true,
  });

  void _defaultNavigate(BuildContext context) {
    if (currentStep < questionRoutes.length - 1) {
      Navigator.of(context).pushNamed(questionRoutes[currentStep + 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: QuestionHeader(
                  currentStep: currentStep,
                  totalSteps: totalSteps,
                  onBack: onBack,
                  onSkip: onSkip,
                  showBackButton: showBackButton,
                  showSkipButton: showSkipButton,
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.displaySmall
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.headlineMedium!.secondary(context)
                      ),
                      const SizedBox(height: 40),
                      content,
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: buttonText,
                    onPressed: isFormValid
                        ? (onNext ?? () => _defaultNavigate(context))
                        : null,
                    isDisabled: !isFormValid,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// Global state management for questions data
class QuestionnaireState extends ChangeNotifier {
  static final QuestionnaireState _instance = QuestionnaireState._internal();
  factory QuestionnaireState() => _instance;
  QuestionnaireState._internal();

  QuestionPageData _data = const QuestionPageData();

  QuestionPageData get data => _data;

  void updateData(QuestionPageData newData) {
    _data = newData;
    notifyListeners();

    // Print current payload for debugging
    print('=== QUESTIONNAIRE PAYLOAD ===');
    print(_data.toJson());
    print('============================');
  }

  void reset() {
    _data = const QuestionPageData();
    notifyListeners();
  }

  Map<String, dynamic> getFinalPayload() {
    final payload = _data.toJson();
    print('=== FINAL PAYLOAD FOR BACKEND ===');
    print(payload);
    print('=================================');
    return payload;
  }
}
