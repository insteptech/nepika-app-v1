import 'package:flutter/material.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/custom_text_field.dart';
import 'package:nepika/data/onboarding/datasources/skincare_professional_datasource.dart';

class SkincareProfessionalScreen extends StatefulWidget {
  final bool isEditMode;

  const SkincareProfessionalScreen({super.key, this.isEditMode = false});

  @override
  State<SkincareProfessionalScreen> createState() =>
      _SkincareProfessionalScreenState();
}

class _SkincareProfessionalScreenState
    extends State<SkincareProfessionalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SkincareProfessionalDataSource _dataSource;

  // Controllers
  final _salonNameController = TextEditingController();
  final _cityController = TextEditingController();

  // Dropdown values
  String? _selectedCountry;
  String? _selectedRole;
  String? _selectedQualification;
  String? _selectedBusinessType;
  String? _selectedExperience;

  // Skin concerns
  List<Map<String, String>> _allConcerns = [];
  final Set<String> _selectedConcerns = {};

  // Consent
  bool _consentProfessional = false;

  // State
  bool _isLoading = false;
  bool _isFetchingConcerns = true;
  bool _isFetchingProfile = false;

  // Dropdown options
  static const List<String> _countries = [
    'India',
    'Ireland',
    'United Kingdom',
    'United States',
    'Australia',
    'Canada',
    'Germany',
    'France',
    'UAE',
    'Singapore',
    'Other',
  ];

  static const List<String> _roles = [
    'Skincare Professional',
    'Dermatologist',
    'Esthetician',
    'Cosmetologist',
    'Beauty Therapist',
    'Other',
  ];

  static const List<String> _qualifications = [
    'ITEC',
    'CIDESCO',
    'NVQ',
    'CIBTAC',
    'VTCT',
    'Diploma in Beauty Therapy',
    'Medical Degree',
    'Other',
  ];

  static const List<String> _businessTypes = [
    'Salon',
    'Clinic',
    'Spa',
    'Freelance',
    'Mobile',
    'Other',
  ];

  static const List<String> _experienceOptions = [
    '0-1 years',
    '1-3 years',
    '3-5 years',
    '5+ years',
    '10+ years',
  ];

  @override
  void initState() {
    super.initState();
    _dataSource = SkincareProfessionalDataSource(ApiBase());
    _initData();
  }

  Future<void> _initData() async {
    // Fetch concerns and optionally the profile data concurrently
    final futures = <Future>[_fetchSkinConcerns()];
    if (widget.isEditMode) {
      if (mounted) setState(() => _isFetchingProfile = true);
      futures.add(_fetchAndPrefillProfile());
    }

    await Future.wait(futures);

    if (mounted && widget.isEditMode) {
      setState(() => _isFetchingProfile = false);
    }
  }

  Future<void> _fetchAndPrefillProfile() async {
    final profile = await _dataSource.fetchProfessionalProfile();
    if (profile != null && mounted) {
      setState(() {
        _salonNameController.text = profile['salon_business_name'] ?? '';
        _cityController.text = profile['city_town'] ?? '';
        _selectedCountry = profile['country'];
        _selectedRole = profile['professional_role'];
        _selectedQualification = profile['qualification'];
        _selectedBusinessType = profile['business_type'];
        _selectedExperience = profile['years_of_experience'];

        // Consent should be re-accepted or preserved?
        // We'll prefill them as true if they exist
        _consentProfessional = profile['consent_professional'] ?? false;

        final concernsList = profile['skin_concerns_treated'] as List<dynamic>?;
        if (concernsList != null) {
          _selectedConcerns.addAll(concernsList.map((e) => e.toString()));
        }
      });
    }
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchSkinConcerns() async {
    final concerns = await _dataSource.fetchSkinConcerns();
    if (mounted) {
      setState(() {
        _allConcerns = concerns;
        _isFetchingConcerns = false;
      });
    }
  }

  bool get _isFormValid {
    return _salonNameController.text.trim().isNotEmpty &&
        _selectedCountry != null &&
        _selectedRole != null &&
        _selectedQualification != null &&
        _selectedConcerns.isNotEmpty &&
        _selectedBusinessType != null &&
        _selectedExperience != null &&
        (widget.isEditMode || _consentProfessional);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      await _dataSource.submitProfessionalOnboarding(
        salonBusinessName: _salonNameController.text.trim(),
        country: _selectedCountry!,
        cityTown:
            _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
        professionalRole: _selectedRole!,
        qualification: _selectedQualification!,
        skinConcernsTreated: _selectedConcerns.toList(),
        businessType: _selectedBusinessType!,
        yearsOfExperience: _selectedExperience!,
        consentProfessional: widget.isEditMode ? true : _consentProfessional,
        consentTerms: true, // Auto-accepting since it's gathered in basic info
      );

      if (mounted) {
        if (widget.isEditMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Professional profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to the professional network!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.dashboardHome, (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () {
            if (widget.isEditMode) {
              Navigator.of(context).pop();
            } else {
              // Navigate to welcome/login screen instead of popping back to onboarding
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
            }
          },
        ),
      ),
      body:
          _isFetchingConcerns || _isFetchingProfile
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          widget.isEditMode
                              ? 'Update Professional Profile'
                              : 'Join as a Skincare Professional',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!widget.isEditMode)
                          Text(
                            'Partner with AI-powered skin analysis and connect with informed clients.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        if (!widget.isEditMode) const SizedBox(height: 32),

                        // Business Details Section
                        _buildSectionHeader('Business Details'),
                        const SizedBox(height: 16),
                        _buildRequiredField(
                          'Salon / Business Name',
                          CustomTextField(
                            controller: _salonNameController,
                            hint: 'Skin Studio Dublin',
                            onChanged: (_) => setState(() {}),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRequiredField(
                                'Country',
                                _buildDropdown(
                                  value: _selectedCountry,
                                  hint: 'Select',
                                  items: _countries,
                                  onChanged:
                                      (v) =>
                                          setState(() => _selectedCountry = v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'City / Town',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  CustomTextField(
                                    controller: _cityController,
                                    hint: 'Dublin',
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRequiredField(
                                'Business Type',
                                _buildDropdown(
                                  value: _selectedBusinessType,
                                  hint: 'Select',
                                  items: _businessTypes,
                                  onChanged:
                                      (v) => setState(
                                        () => _selectedBusinessType = v,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRequiredField(
                                'Years of Experience',
                                _buildDropdown(
                                  value: _selectedExperience,
                                  hint: 'Select',
                                  items: _experienceOptions,
                                  onChanged:
                                      (v) => setState(
                                        () => _selectedExperience = v,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Professional Information Section
                        _buildSectionHeader('Professional Information'),
                        const SizedBox(height: 16),
                        _buildRequiredField(
                          'Professional Role',
                          _buildDropdown(
                            value: _selectedRole,
                            hint: 'Select role',
                            items: _roles,
                            onChanged: (v) => setState(() => _selectedRole = v),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRequiredField(
                          'Qualification',
                          _buildDropdown(
                            value: _selectedQualification,
                            hint: 'Select qualification',
                            items: _qualifications,
                            onChanged:
                                (v) =>
                                    setState(() => _selectedQualification = v),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For information purposes only. Verification may be introduced later.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Skin Concerns Treated
                        _buildRequiredField(
                          'Skin Concerns Treated',
                          _isFetchingConcerns
                              ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                              : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _allConcerns.map((concern) {
                                      final id = concern['id'] ?? '';
                                      final name = concern['name'] ?? '';
                                      final isSelected = _selectedConcerns
                                          .contains(id);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedConcerns.remove(id);
                                            } else {
                                              _selectedConcerns.add(id);
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? theme
                                                          .colorScheme
                                                          .primary
                                                      : theme.dividerColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            name,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                        ),

                        const SizedBox(height: 32),

                        // Consent Section (Only for new registrations)
                        if (!widget.isEditMode) ...[
                          _buildSectionHeader('Consent'),
                          const SizedBox(height: 16),
                          _buildConsentCheckbox(
                            value: _consentProfessional,
                            text:
                                'I confirm that I am a qualified skincare professional and that the information provided is accurate.',
                            onChanged:
                                (v) => setState(
                                  () => _consentProfessional = v ?? false,
                                ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Join Button
                        CustomButton(
                          text: widget.isEditMode ? 'Update' : 'Join',
                          onPressed: _isFormValid ? _handleSubmit : null,
                          isLoading: _isLoading,
                          isDisabled: !_isFormValid,
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRequiredField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
        color:
            theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: theme.textTheme.bodyMedium),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildConsentCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
    bool hasLinks = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                hasLinks
                    ? RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Text(
                      text,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
          ),
        ],
      ),
    );
  }
}
