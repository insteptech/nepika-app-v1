# SOLID Widget Architecture

A comprehensive Flutter widget library following SOLID principles and Test-Driven Development (TDD) approach.

## Architecture Overview

This widget library implements the SOLID principles:

- **S**ingle Responsibility Principle (SRP): Each widget has one clear purpose
- **O**pen/Closed Principle (OCP): Widgets are open for extension, closed for modification
- **L**iskov Substitution Principle (LSP): Derived widgets can replace base widgets seamlessly
- **I**nterface Segregation Principle (ISP): Mixins provide focused behavior contracts
- **D**ependency Inversion Principle (DIP): Widgets depend on abstractions, not concrete implementations

## Structure

```
lib/core/widgets/
├── base/                    # Base classes and abstract widgets
│   └── base_widgets.dart    # Template method patterns and base implementations
├── mixins/                  # Behavior mixins (ISP)
│   └── widget_behaviors.dart # Reusable behavior contracts
├── buttons/                 # Button components
│   └── action_buttons.dart  # Primary, Secondary, Text buttons
├── inputs/                  # Form input components
│   └── form_inputs.dart     # Text inputs, Email, Password inputs
├── selectors/               # Selection components
│   └── selection_widgets.dart # Dropdown, Chips, Radio groups
├── layouts/                 # Layout components
│   └── layout_components.dart # Cards, Headers, Forms, Responsive layouts
├── navigation/              # Navigation components
│   └── navigation_components.dart # NavBars, Drawers, AppBars, Tabs
├── common/                  # Utility components
│   └── utility_widgets.dart # Loading, Error, Empty states, Badges
└── index.dart              # Main export file
```

## Key Components

### Base Architecture

#### BaseButton
```dart
abstract class BaseButton extends StatelessWidget {
  // Template method pattern - subclasses override specific parts
  Widget buildButtonContent(BuildContext context);
  ButtonStyle getButtonStyle(BuildContext context);
}
```

#### BaseFormField<T>
```dart
abstract class BaseFormField<T> extends StatefulWidget {
  // Generic form field with validation support
}
```

#### BaseSelector<T>
```dart
abstract class BaseSelector<T> extends StatefulWidget {
  // Generic selection widget for options
}
```

### Behavior Mixins

#### FormFieldBehavior<T>
- `T? get value`
- `void setValue(T? value)`
- `void clear()`

#### ValidatableBehavior
- `bool validate()`
- `String? get errorMessage`

#### SelectableBehavior<T>
- `T? get selectedValue`
- `List<T> get options`
- `void select(T value)`
- `void deselect()`

#### ThemeAwareBehavior
- `Color getPrimaryColor(BuildContext context)`
- `TextTheme getTextTheme(BuildContext context)`
- Helper methods for consistent theming

### Button Components

#### PrimaryButton
```dart
PrimaryButton(
  text: 'Submit',
  onPressed: () => handleSubmit(),
  icon: Icons.check,
)
```

#### SecondaryButton
```dart
SecondaryButton(
  text: 'Cancel',
  onPressed: () => handleCancel(),
)
```

#### TextActionButton
```dart
TextActionButton(
  text: 'Learn More',
  icon: Icons.info,
  onPressed: () => showInfo(),
)
```

### Input Components

#### CustomTextInput
```dart
CustomTextInput(
  label: 'Full Name',
  hint: 'Enter your full name',
  isRequired: true,
  validator: (value) => value?.isEmpty == true ? 'Required' : null,
  onChanged: (value) => setState(() => name = value),
)
```

#### EmailInput
```dart
EmailInput(
  onChanged: (email) => updateEmail(email),
)
```

#### PasswordInput
```dart
PasswordInput(
  showToggle: true,
  onChanged: (password) => updatePassword(password),
)
```

### Selection Components

#### DropdownSelector<T>
```dart
DropdownSelector<String>(
  options: ['Option 1', 'Option 2', 'Option 3'],
  itemBuilder: (item) => item,
  label: 'Choose Option',
  onSelectionChanged: (value) => handleSelection(value),
)
```

#### ChipSelector<T>
```dart
ChipSelector<String>(
  options: ['Tag 1', 'Tag 2', 'Tag 3'],
  itemBuilder: (item) => item,
  multiSelect: true,
  onMultiSelectionChanged: (values) => handleTags(values),
)
```

#### RadioGroupSelector<T>
```dart
RadioGroupSelector<String>(
  options: ['Option A', 'Option B'],
  itemBuilder: (item) => item,
  direction: Axis.vertical,
  onSelectionChanged: (value) => handleRadioSelection(value),
)
```

### Layout Components

#### ResponsiveCard
```dart
ResponsiveCard(
  maxWidth: 400,
  child: FormLayout(
    children: [
      EmailInput(),
      PasswordInput(),
      PrimaryButton(text: 'Login'),
    ],
  ),
)
```

#### ProgressLayout
```dart
ProgressLayout(
  currentStep: 2,
  totalSteps: 5,
  title: 'Personal Information',
  subtitle: 'Tell us about yourself',
  child: YourFormContent(),
)
```

#### FormLayout
```dart
FormLayout(
  spacing: 20,
  children: [
    CustomTextInput(label: 'Name'),
    EmailInput(),
    PrimaryButton(text: 'Submit'),
  ],
)
```

### Navigation Components

#### QuestionnaireNavigation
```dart
QuestionnaireNavigation(
  showBackButton: true,
  showSkipButton: true,
  onBackPressed: () => goBack(),
  onSkipPressed: () => skipToNext(),
  onNextPressed: () => goNext(),
  isNextEnabled: isFormValid,
)
```

#### CustomAppBar
```dart
CustomAppBar(
  title: 'Settings',
  actions: [
    IconButton(icon: Icons.save, onPressed: save),
  ],
)
```

### Utility Components

#### LoadingIndicator
```dart
LoadingIndicator(
  message: 'Processing...',
  overlay: true,
)
```

#### ErrorDisplay
```dart
ErrorDisplay(
  errorMessage: 'Something went wrong',
  actionLabel: 'Retry',
  onAction: () => retry(),
)
```

#### EmptyState
```dart
EmptyState(
  title: 'No items found',
  subtitle: 'Try adjusting your search criteria',
  icon: Icons.search_off,
  actionLabel: 'Reset Filters',
  onAction: () => resetFilters(),
)
```

## Test-Driven Development (TDD)

All components include comprehensive tests:

```dart
testWidgets('PrimaryButton should render correctly', (WidgetTester tester) async {
  bool wasPressed = false;
  
  await tester.pumpWidget(
    MaterialApp(
      home: PrimaryButton(
        text: 'Test Button',
        onPressed: () => wasPressed = true,
      ),
    ),
  );
  
  expect(find.text('Test Button'), findsOneWidget);
  await tester.tap(find.byType(ElevatedButton));
  expect(wasPressed, isTrue);
});
```

## Usage Examples

### Basic Form
```dart
class LoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: FormLayout(
        children: [
          SectionHeader(title: 'Login'),
          EmailInput(onChanged: updateEmail),
          PasswordInput(onChanged: updatePassword),
          PrimaryButton(
            text: 'Sign In',
            onPressed: isValid ? handleLogin : null,
          ),
        ],
      ),
    );
  }
}
```

### Questionnaire Page
```dart
class QuestionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressLayout(
        currentStep: 3,
        totalSteps: 6,
        title: 'Your Preferences',
        child: FormLayout(
          children: [
            ChipSelector<String>(
              options: ['Option 1', 'Option 2', 'Option 3'],
              itemBuilder: (item) => item,
              multiSelect: true,
              onMultiSelectionChanged: handleSelection,
            ),
          ],
        ),
      ),
      bottomNavigationBar: QuestionnaireNavigation(
        onBackPressed: goBack,
        onNextPressed: goNext,
        isNextEnabled: hasSelection,
      ),
    );
  }
}
```

## Migration from Legacy Components

The SOLID architecture coexists with existing legacy components. Migrate gradually by:

1. **Replace simple widgets first**: Start with buttons and inputs
2. **Update form pages**: Use FormLayout and new input components
3. **Refactor questionnaire flow**: Use QuestionnaireNavigation and ProgressLayout
4. **Add tests**: Follow TDD approach for new components

## Benefits

- **Maintainability**: Clear separation of concerns
- **Testability**: Easy to unit test individual components
- **Reusability**: Mixins and base classes promote code reuse
- **Consistency**: Standardized styling and behavior
- **Extensibility**: Easy to add new components following established patterns
- **Type Safety**: Generic types ensure compile-time safety
- **Performance**: Efficient widget composition with minimal rebuilds

## Getting Started

1. Import the widget library:
```dart
import 'package:nepika/core/widgets/index.dart';
```

2. Use components in your pages:
```dart
PrimaryButton(
  text: 'Get Started',
  onPressed: () => Navigator.pushNamed(context, '/onboarding'),
)
```

3. Run tests to verify functionality:
```bash
flutter test test/core/widgets/solid_widgets_test.dart
```

## Future Enhancements

- [ ] Dark mode support with ThemeAwareBehavior
- [ ] Accessibility improvements (a11y)
- [ ] Animation mixins for smooth transitions
- [ ] Responsive breakpoint system
- [ ] Component documentation with Storybook
- [ ] Performance optimizations with const constructors
- [ ] Internationalization support
- [ ] Custom theming system
