import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../widgets/onboarding_layout.dart';

class GoalScreen extends StatelessWidget {
  final UserGoal? initialGoal;
  final Function(UserGoal) onGoalSelected;
  final VoidCallback onBack;

  const GoalScreen({
    Key? key,
    this.initialGoal,
    required this.onGoalSelected,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Какая у вас цель?',
      child: Column(
        children: [
          _GoalButton(
            title: 'Похудеть',
            description: 'Снизить процент жира, улучшить форму тела',
            isSelected: initialGoal == UserGoal.LOSE_WEIGHT,
            onTap: () => onGoalSelected(UserGoal.LOSE_WEIGHT),
          ),
          const SizedBox(height: 16),
          _GoalButton(
            title: 'Сохранить вес',
            description: 'Поддерживать текущую форму и здоровье',
            isSelected: initialGoal == UserGoal.MAINTAIN_WEIGHT,
            onTap: () => onGoalSelected(UserGoal.MAINTAIN_WEIGHT),
          ),
          const SizedBox(height: 16),
          _GoalButton(
            title: 'Набрать вес',
            description: 'Увеличить мышечную массу, стать сильнее',
            isSelected: initialGoal == UserGoal.GAIN_WEIGHT,
            onTap: () => onGoalSelected(UserGoal.GAIN_WEIGHT),
          ),
        ],
      ),
      onNext: initialGoal != null 
        ? () { onGoalSelected(initialGoal!); }
        : null,
      onBack: onBack,
    );
  }
}

class _GoalButton extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalButton({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 