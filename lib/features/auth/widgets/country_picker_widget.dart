import 'package:flutter/material.dart';
import '../services/country_service.dart';

class CountryPickerWidget extends StatelessWidget {
  final Country selectedCountry;
  final Function(Country) onCountrySelected;

  const CountryPickerWidget({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCountryPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${selectedCountry.flag} ${selectedCountry.code}',
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
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryPickerContent(
        onCountrySelected: (country) {
          Navigator.pop(context);
          onCountrySelected(country);
        },
      ),
    );
  }
}

class _CountryPickerContent extends StatelessWidget {
  final Function(Country) onCountrySelected;

  const _CountryPickerContent({
    required this.onCountrySelected,
  });

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => onCountrySelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}