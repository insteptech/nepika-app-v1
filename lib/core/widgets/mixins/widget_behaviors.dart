import 'package:flutter/material.dart';

// Mixins for reusable behaviors following SOLID principles
// Interface Segregation Principle (I) - Specific behaviors for specific needs

/// Mixin for form field behavior
mixin FormFieldBehavior<T> {
  T? get value;
  void setValue(T? value);
  void clear();
}

/// Mixin for validation behavior
mixin ValidatableBehavior {
  bool validate();
  String? get errorMessage;
}

/// Mixin for selection behavior
mixin SelectableBehavior<T> {
  T? get selectedValue;
  List<T> get options;
  void select(T value);
  void deselect();
}

/// Mixin for navigation behavior
mixin NavigableBehavior {
  void goBack();
  void goNext();
  void skip();
}

/// Mixin for progress tracking
mixin ProgressBehavior {
  int get currentStep;
  int get totalSteps;
  double get progress => currentStep / totalSteps;
}

/// Mixin for theme-aware widgets
mixin ThemeAwareBehavior {
  Color getPrimaryColor(BuildContext context) => Theme.of(context).primaryColor;
  Color getBackgroundColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  TextTheme getTextTheme(BuildContext context) => Theme.of(context).textTheme;
  ButtonThemeData getButtonTheme(BuildContext context) => Theme.of(context).buttonTheme;
}

/// Mixin for loading state management
mixin LoadingStateBehavior {
  bool get isLoading;
  void setLoading(bool loading);
}

/// Mixin for error state management
mixin ErrorStateBehavior {
  String? get errorMessage;
  bool get hasError => errorMessage != null;
  void setError(String? error);
  void clearError() => setError(null);
}
