class UserBasicsModel {
  final String fullName;
  final String email;

  UserBasicsModel({required this.fullName, required this.email});

  factory UserBasicsModel.fromJson(Map<String, dynamic> json) {
    return UserBasicsModel(
      fullName: json['full_name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
    };
  }
}

class UserDetailsModel {
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

  UserDetailsModel({
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

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      heightUnit: json['height_unit'],
      heightCm: json['height_cm']?.toDouble(),
      heightFeet: json['height_feet']?.toDouble(),
      heightInches: json['height_inches']?.toDouble(),
      weightUnit: json['weight_unit'],
      weightValue: json['weight_value'].toDouble(),
      waistUnit: json['waist_unit'],
      waistValue: json['waist_value'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'height_unit': heightUnit,
      'height_cm': heightCm,
      'height_feet': heightFeet,
      'height_inches': heightInches,
      'weight_unit': weightUnit,
      'weight_value': weightValue,
      'waist_unit': waistUnit,
      'waist_value': waistValue,
    };
  }
}

class LifestyleModel {
  final String jobType;
  final String workEnvironment;
  final String stressLevel;
  final String physicalActivityLevel;
  final String hydrationEntry;

  LifestyleModel({
    required this.jobType,
    required this.workEnvironment,
    required this.stressLevel,
    required this.physicalActivityLevel,
    required this.hydrationEntry,
  });

  factory LifestyleModel.fromJson(Map<String, dynamic> json) {
    return LifestyleModel(
      jobType: json['job_type'],
      workEnvironment: json['work_environment'],
      stressLevel: json['stress_level'],
      physicalActivityLevel: json['physical_activity_level'],
      hydrationEntry: json['hydration_entry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_type': jobType,
      'work_environment': workEnvironment,
      'stress_level': stressLevel,
      'physical_activity_level': physicalActivityLevel,
      'hydration_entry': hydrationEntry,
    };
  }
}

class SkinTypeModel {
  final String skinType;

  SkinTypeModel({required this.skinType});

  factory SkinTypeModel.fromJson(Map<String, dynamic> json) {
    return SkinTypeModel(skinType: json['skin_type']);
  }

  Map<String, dynamic> toJson() => {'skin_type': skinType};
}

class NaturalRhythmModel {
  final bool doYouMenstruate;

  NaturalRhythmModel({required this.doYouMenstruate});

  factory NaturalRhythmModel.fromJson(Map<String, dynamic> json) {
    return NaturalRhythmModel(doYouMenstruate: json['do_you_menstruate']);
  }

  Map<String, dynamic> toJson() => {'do_you_menstruate': doYouMenstruate};
}

class MenstrualCycleOverviewModel {
  final String currentPhase;
  final String cycleRegularity;
  final List<String> pmsSymptoms;

  MenstrualCycleOverviewModel({
    required this.currentPhase,
    required this.cycleRegularity,
    required this.pmsSymptoms,
  });

  factory MenstrualCycleOverviewModel.fromJson(Map<String, dynamic> json) {
    return MenstrualCycleOverviewModel(
      currentPhase: json['current_phase'],
      cycleRegularity: json['cycle_regularity'],
      pmsSymptoms: List<String>.from(json['pms_symptoms'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_phase': currentPhase,
      'cycle_regularity': cycleRegularity,
      'pms_symptoms': pmsSymptoms,
    };
  }
}

class CycleDetailsModel {
  final String cycleStartDate;
  final int cycleLengthDays;
  final int currentDayInCycle;

  CycleDetailsModel({
    required this.cycleStartDate,
    required this.cycleLengthDays,
    required this.currentDayInCycle,
  });

  factory CycleDetailsModel.fromJson(Map<String, dynamic> json) {
    return CycleDetailsModel(
      cycleStartDate: json['cycle_start_date'],
      cycleLengthDays: json['cycle_length_days'],
      currentDayInCycle: json['current_day_in_cycle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle_start_date': cycleStartDate,
      'cycle_length_days': cycleLengthDays,
      'current_day_in_cycle': currentDayInCycle,
    };
  }
}

class MenopauseModel {
  final String menopauseStatus;
  final String? lastPeriodDate;
  final List<String> commonSymptoms;
  final bool usingHrtSupplements;

  MenopauseModel({
    required this.menopauseStatus,
    this.lastPeriodDate,
    required this.commonSymptoms,
    required this.usingHrtSupplements,
  });

  factory MenopauseModel.fromJson(Map<String, dynamic> json) {
    return MenopauseModel(
      menopauseStatus: json['menopause_status'],
      lastPeriodDate: json['last_period_date'],
      commonSymptoms: List<String>.from(json['common_symptoms']),
      usingHrtSupplements: json['using_hrt_supplements'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menopause_status': menopauseStatus,
      'last_period_date': lastPeriodDate,
      'common_symptoms': commonSymptoms,
      'using_hrt_supplements': usingHrtSupplements,
    };
  }
}

class SkinGoalsModel {
  final List<String> acneBlemishGoals;
  final List<String> glowRadianceGoals;
  final List<String> hydrationTextureGoals;
  final bool notSureYet;

  SkinGoalsModel({
    required this.acneBlemishGoals,
    required this.glowRadianceGoals,
    required this.hydrationTextureGoals,
    required this.notSureYet,
  });

  factory SkinGoalsModel.fromJson(Map<String, dynamic> json) {
    return SkinGoalsModel(
      acneBlemishGoals: List<String>.from(json['acne_blemish_goals']),
      glowRadianceGoals: List<String>.from(json['glow_radiance_goals']),
      hydrationTextureGoals: List<String>.from(json['hydration_texture_goals']),
      notSureYet: json['not_sure_yet'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acne_blemish_goals': acneBlemishGoals,
      'glow_radiance_goals': glowRadianceGoals,
      'hydration_texture_goals': hydrationTextureGoals,
      'not_sure_yet': notSureYet,
    };
  }
}
