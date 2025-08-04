class UserBasicsEntity {
  final String fullName;
  final String email;

  UserBasicsEntity({required this.fullName, required this.email});
}

class UserDetailsEntity {
  final String gender;
  final String dateOfBirth;
  final String heightUnit;
  final double? heightCm;
  final double? heightFeet;
  final double? heightInches;
  final String weightUnit;
  final double weightValue;
  final String waistUnit;
  final double waistValue;

  UserDetailsEntity({
    required this.gender,
    required this.dateOfBirth,
    required this.heightUnit,
    this.heightCm,
    this.heightFeet,
    this.heightInches,
    required this.weightUnit,
    required this.weightValue,
    required this.waistUnit,
    required this.waistValue,
  });
}

class LifestyleEntity {
  final String jobType;
  final String workEnvironment;
  final String stressLevel;
  final String physicalActivityLevel;
  final String hydrationEntry;

  LifestyleEntity({
    required this.jobType,
    required this.workEnvironment,
    required this.stressLevel,
    required this.physicalActivityLevel,
    required this.hydrationEntry,
  });
}

class SkinTypeEntity {
  final String skinType;

  SkinTypeEntity({required this.skinType});
}

class NaturalRhythmEntity {
  final bool doYouMenstruate;

  NaturalRhythmEntity({required this.doYouMenstruate});
}

class MenstrualCycleOverviewEntity {
  final String currentPhase;
  final String cycleRegularity;
  final List<String> pmsSymptoms;

  MenstrualCycleOverviewEntity({
    required this.currentPhase,
    required this.cycleRegularity,
    required this.pmsSymptoms,
  });
}

class CycleDetailsEntity {
  final String cycleStartDate;
  final int cycleLengthDays;
  final int currentDayInCycle;

  CycleDetailsEntity({
    required this.cycleStartDate,
    required this.cycleLengthDays,
    required this.currentDayInCycle,
  });
}

class MenopauseEntity {
  final String menopauseStatus;
  final String? lastPeriodDate;
  final List<String> commonSymptoms;
  final bool usingHrtSupplements;

  MenopauseEntity({
    required this.menopauseStatus,
    this.lastPeriodDate,
    required this.commonSymptoms,
    required this.usingHrtSupplements,
  });
}

class SkinGoalsEntity {
  final List<String> acneBlemishGoals;
  final List<String> glowRadianceGoals;
  final List<String> hydrationTextureGoals;
  final bool notSureYet;

  SkinGoalsEntity({
    required this.acneBlemishGoals,
    required this.glowRadianceGoals,
    required this.hydrationTextureGoals,
    required this.notSureYet,
  });
}
