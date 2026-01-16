import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/features/support/bloc/feedback_bloc.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  int _selectedRating = 0;
  bool _isMessageValid = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_validateMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _validateMessage() {
    setState(() {
      _isMessageValid = _messageController.text.trim().length >= 3;
    });
  }

  void _submitFeedback(BuildContext context) {
    if (!_isMessageValid) return;

    // Treat 0 as null if user didn't select a rating
    final rating = _selectedRating > 0 ? _selectedRating : null;
    
    context.read<FeedbackBloc>().add(
          SubmitFeedbackEvent(
            text: _messageController.text.trim(),
            rating: rating,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => ServiceLocator.get<FeedbackBloc>(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: CustomBackButton()
          ),
          leadingWidth: 80,
          title: Text(
            'Feedback',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocConsumer<FeedbackBloc, FeedbackState>(
          listener: (context, state) {
            if (state is FeedbackSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thank you for your feedback!'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
              Navigator.pop(context);
            } else if (state is FeedbackError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is FeedbackSubmitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How is your experience?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rating Section
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRating = starIndex;
                                  });
                                },
                          icon: Icon(
                            starIndex <= _selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40,
                            color: starIndex <= _selectedRating
                                ? Colors.amber
                                : theme.disabledColor,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Feedback Text Field
                  TextField(
                    controller: _messageController,
                    maxLines: 6,
                    maxLength: 2000,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Tell us what you think...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (isLoading || !_isMessageValid)
                          ? null
                          : () => _submitFeedback(context),
                      style: ElevatedButton.styleFrom(
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'Submit Feedback',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
