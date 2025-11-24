import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../domain/auth/entities/delete_account_entities.dart';
import '../bloc/delete_account_bloc.dart';
import '../bloc/delete_account_event.dart';
import '../bloc/delete_account_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog for account deletion with reason selection
class DeleteAccountConfirmationDialog extends StatelessWidget {
  const DeleteAccountConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.ServiceLocator.get<DeleteAccountBloc>()
        ..add(const LoadDeleteReasons()),
      child: const _DeleteAccountDialogContent(),
    );
  }
}

class _DeleteAccountDialogContent extends StatefulWidget {
  const _DeleteAccountDialogContent();

  @override
  State<_DeleteAccountDialogContent> createState() => _DeleteAccountDialogContentState();
}

class _DeleteAccountDialogContentState extends State<_DeleteAccountDialogContent> {
  int? _selectedReasonId;
  final TextEditingController _commentsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitDeletion() async {
    if (_selectedReasonId == null) {
      ScaffoldMessenger.of(Navigator.of(context).context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for deletion'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(Navigator.of(context).context).showSnackBar(
            const SnackBar(
              content: Text('Authentication token not found'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
            ),
          );
        }
        return;
      }

      final request = DeleteAccountRequestEntity(
        deleteReasonId: _selectedReasonId!,
        additionalComments: _commentsController.text.trim().isNotEmpty 
            ? _commentsController.text.trim() 
            : null,
      );

      if (mounted) {
        context.read<DeleteAccountBloc>().add(
          SubmitDeleteAccount(token: token, request: request),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(Navigator.of(context).context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteAccountBloc, DeleteAccountState>(
      listener: (context, state) {
        if (state is DeleteAccountLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is DeleteAccountSuccess) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pop();
          _clearDataAndNavigateToSplash(context);
        } else if (state is DeleteAccountError) {
          setState(() {
            _isLoading = false;
          });
          // Use the root scaffold messenger to show snackbar above dialog
          ScaffoldMessenger.of(Navigator.of(context).context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
              margin: const EdgeInsets.only(
                bottom: 80,
                left: 20,
                right: 20,
              ),
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'We\'re sorry to see you go! Your account and all data will be permanently deleted.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: BlocBuilder<DeleteAccountBloc, DeleteAccountState>(
                    builder: (context, state) {
                      if (state is DeleteReasonsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (state is DeleteReasonsLoaded) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Please tell us why you\'re leaving:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...state.reasons.map((reason) => 
                              RadioListTile<int>(
                                title: Text(reason.reasonText),
                                subtitle: Text(
                                  reason.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                value: reason.id,
                                groupValue: _selectedReasonId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedReasonId = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Additional comments (optional):',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _commentsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tell us more about your experience...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        );
                      } else if (state is DeleteReasonsError) {
                        return Column(
                          children: [
                            Text(
                              'Error loading reasons: ${state.message}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                context.read<DeleteAccountBloc>().add(
                                  const LoadDeleteReasons(),
                                );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitDeletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Delete Account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _clearDataAndNavigateToSplash(BuildContext context) async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      
      // Clear all user data from local storage
      await sharedPrefs.remove(AppConstants.accessTokenKey);
      await sharedPrefs.remove(AppConstants.refreshTokenKey);
      await sharedPrefs.remove(AppConstants.userTokenKey);
      await sharedPrefs.remove(AppConstants.userDataKey);
      await sharedPrefs.remove(AppConstants.onboardingKey);
      // Clear any other app-specific keys as needed
      
      if (context.mounted) {
        // Navigate to splash screen and clear all navigation stack
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.splash,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
      if (context.mounted) {
        // Fallback: still navigate to splash screen even if clearing fails
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.splash,
          (route) => false,
        );
      }
    }
  }
}