import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/country_service.dart';
import '../services/phone_formatting_service.dart';

class PhoneInputWidget extends StatefulWidget {
  final Function(String) onPhoneChanged;
  final Function(bool) onValidationChanged;
  final String? initialPhone;

  const PhoneInputWidget({
    super.key,
    required this.onPhoneChanged,
    required this.onValidationChanged,
    this.initialPhone,
  });

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  late final TextEditingController _phoneController;
  late Country _selectedCountry;
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryService.getDefaultCountry();
    _phoneController = TextEditingController(text: widget.initialPhone);
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phoneNumber = PhoneFormattingService.getDigitsOnly(widget.initialPhone!);
      _updateValidation();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCountryPickerContent(context),
    );
  }

  Widget _buildCountryPickerContent(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Country',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: CountryService.countries.length,
              itemBuilder: (context, index) {
                final country = CountryService.countries[index];
                return ListTile(
                  leading: Text(
                    country.flag,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  title: Text(
                    country.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: Text(
                    country.code,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _onCountryChanged(country);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onCountryChanged(Country country) {
    setState(() {
      _selectedCountry = country;
      _phoneController.clear();
      _phoneNumber = '';
    });
    _updateValidation();
  }

  void _onPhoneChanged(String value) {
    final digitsOnly = PhoneFormattingService.getDigitsOnly(value);
    setState(() {
      _phoneNumber = digitsOnly;
    });
    
    final fullNumber = _selectedCountry.code + digitsOnly;
    widget.onPhoneChanged(fullNumber);
    _updateValidation();
  }

  void _updateValidation() {
    final isValid = PhoneFormattingService.isValidPhoneLength(
      _phoneNumber, 
      _selectedCountry.limit,
    );
    widget.onValidationChanged(isValid);
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your\nphone number';
    }
    
    final digitsOnly = PhoneFormattingService.getDigitsOnly(value);
    if (digitsOnly.length != _selectedCountry.limit) {
      return 'Phone number should be ${_selectedCountry.limit} digits';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      // mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicWidth(
          // width: 120,
          child: InkWell(
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0x663898ED),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_selectedCountry.flag} ${_selectedCountry.code}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        // const SizedBox(width: 8),
        IntrinsicWidth(
          child: UnderlinedTextField(
            key: ValueKey(_selectedCountry.hint),
            hint: _selectedCountry.hint,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.start,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            inputFormatters: [
              PhoneNumberFormatter(_selectedCountry.format),
              LengthLimitingTextInputFormatter(_selectedCountry.format.length),
            ],
            onChanged: _onPhoneChanged,
            textStyle: Theme.of(context).textTheme.displaySmall,
            hintStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
            validator: _validatePhone,
          ),
        )
      ],
    );
  }
}