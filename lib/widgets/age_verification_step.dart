import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AgeVerificationStep extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime dateOfBirth, bool requiresParentalConsent,
      bool parentalConsentGiven) onDateSelected;

  const AgeVerificationStep({
    Key? key,
    this.initialDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<AgeVerificationStep> createState() => _AgeVerificationStepState();
}

class _AgeVerificationStepState extends State<AgeVerificationStep> {
  DateTime? _selectedDate;
  bool _parentalConsentGiven = false;
  bool _showParentalConsent = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _checkAge();
    }
  }

  int? _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  void _checkAge() {
    if (_selectedDate == null) return;

    final age = _calculateAge(_selectedDate!);
    if (age != null && age < 13) {
      setState(() => _showParentalConsent = true);
    } else {
      setState(() {
        _showParentalConsent = false;
        _parentalConsentGiven = false;
      });
    }

    // Notify parent widget
    widget.onDateSelected(
      _selectedDate!,
      age! < 13,
      _parentalConsentGiven,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your date of birth',
      fieldLabelText: 'Date of Birth',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _checkAge();
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = _selectedDate != null ? _calculateAge(_selectedDate!) : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age Verification',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please confirm your date of birth to continue',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cake_outlined,
                        color: theme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date of Birth',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Tap to select',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (age != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: age >= 13
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: age >= 13
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    age >= 13 ? Icons.check_circle : Icons.info,
                    color: age >= 13 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      age >= 13
                          ? 'You are $age years old'
                          : 'You are $age years old - Parental consent required',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: age >= 13 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_showParentalConsent) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.family_restroom,
                        color: Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Parental Consent Required',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Since you are under 13 years old, we need permission from your parent or guardian to create an account. This is required by the Children\'s Online Privacy Protection Act (COPPA).',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchURL('https://www.versewing.com/child-safety-policy'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Read our Child Safety Policy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'What this means:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          'Your parent/guardian must give permission',
                          theme,
                        ),
                        _buildBulletPoint(
                          'They will receive notifications about your account',
                          theme,
                        ),
                        _buildBulletPoint(
                          'Content will be filtered for your safety',
                          theme,
                        ),
                        _buildBulletPoint(
                          'Some features may be restricted',
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _parentalConsentGiven,
                    onChanged: (value) {
                      setState(() {
                        _parentalConsentGiven = value ?? false;
                      });
                      widget.onDateSelected(
                        _selectedDate!,
                        true,
                        _parentalConsentGiven,
                      );
                      HapticFeedback.selectionClick();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I confirm that I have my parent or guardian\'s permission to create this account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedDate != null && age! >= 13) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your date of birth helps us provide age-appropriate content and comply with child safety regulations.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
