import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/index.dart';
import 'user_details_page.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateFormState);
    _emailController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateFormState);
    _emailController.removeListener(_updateFormState);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    final isValid = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty;
    setState(() {
      _isFormValid = isValid;
    });
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UserDetailsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionPage(
      currentStep: 1,
      totalSteps: 6,
      title: 'Let\'s Get to Know You',
      subtitle: 'Just the basics — we promise it\'s quick',
      buttonText: 'Next',
      isFormValid: _isFormValid,
      onNext: _handleNext,
      showBackButton: false,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full name',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 3),
            UnderlinedTextField(
              controller: _nameController,
              hint: '',
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            Text(
              'Email id',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 3),
            UnderlinedTextField(
              controller: _emailController,
              hint: '',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
