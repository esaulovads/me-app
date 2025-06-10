import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../widgets/onboarding_layout.dart';

class GenderScreen extends StatelessWidget {
  final Gender? initialGender;
  final Function(Gender) onGenderSelected;
  final VoidCallback onBack;

  const GenderScreen({
    Key? key,
    this.initialGender,
    required this.onGenderSelected,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Укажите ваш пол',
      child: Column(
        children: [
          _GenderButton(
            title: 'Мужской',
            isSelected: initialGender == Gender.male,
            onTap: () => onGenderSelected(Gender.male),
          ),
          const SizedBox(height: 16),
          _GenderButton(
            title: 'Женский',
            isSelected: initialGender == Gender.female,
            onTap: () => onGenderSelected(Gender.female),
          ),
        ],
      ),
      onNext: initialGender != null 
        ? () { onGenderSelected(initialGender!); }
        : null,
      onBack: onBack,
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
} 