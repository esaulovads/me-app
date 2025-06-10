import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../widgets/onboarding_layout.dart';

class GoalScreen extends StatelessWidget {
  final UserGoal? initialGoal;
  final Function(UserGoal) onGoalSelected;
  final VoidCallback onBack;
  final double? height; // в сантиметрах
  final double? weight; // в килограммах

  const GoalScreen({
    Key? key,
    this.initialGoal,
    required this.onGoalSelected,
    required this.onBack,
    this.height,
    this.weight,
  }) : super(key: key);

  // Расчет ИМТ
  double? _calculateBMI() {
    if (height == null || weight == null) return null;
    // Переводим рост из сантиметров в метры
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Проверка, можно ли выбрать цель "похудеть"
  bool _canLoseWeight() {
    final bmi = _calculateBMI();
    // Если ИМТ не может быть рассчитан или больше 18.5, разрешаем выбор
    return bmi == null || bmi > 18.5;
  }

  @override
  Widget build(BuildContext context) {
    final canLoseWeight = _canLoseWeight();

    return OnboardingLayout(
      title: 'Какая у вас цель?',
      child: Column(
        children: [
          _GoalButton(
            title: 'Похудеть',
            description: canLoseWeight 
              ? 'Снизить процент жира, улучшить форму тела'
              : 'Недоступно при низком индексе массы тела (ИМТ < 18.5)',
            isSelected: initialGoal == UserGoal.LOSE_WEIGHT && canLoseWeight,
            onTap: canLoseWeight ? () => onGoalSelected(UserGoal.LOSE_WEIGHT) : null,
            isDisabled: !canLoseWeight,
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
  final VoidCallback? onTap;
  final bool isDisabled;

  const _GoalButton({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled 
              ? Colors.grey[300]!
              : isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDisabled 
            ? Colors.grey[100]
            : isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1) 
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDisabled 
                  ? Colors.grey[500]
                  : isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled 
                  ? Colors.grey[500]
                  : isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 