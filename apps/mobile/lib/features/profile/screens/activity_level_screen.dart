import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../widgets/onboarding_layout.dart';

class ActivityLevelScreen extends StatelessWidget {
  final ActivityLevel? initialLevel;
  final Function(ActivityLevel) onLevelSelected;
  final VoidCallback onBack;

  const ActivityLevelScreen({
    Key? key,
    this.initialLevel,
    required this.onLevelSelected,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Ваш уровень активности',
      child: SingleChildScrollView(
        child: Column(
          children: [
            _ActivityButton(
              title: 'Нет активности',
              description: 'Сидячая работа, отсутствие регулярных тренировок',
              isSelected: initialLevel == ActivityLevel.SEDENTARY,
              onTap: () => onLevelSelected(ActivityLevel.SEDENTARY),
            ),
            const SizedBox(height: 16),
            _ActivityButton(
              title: 'Небольшая активность',
              description: 'Легкие тренировки 1-3 раза в неделю',
              isSelected: initialLevel == ActivityLevel.LIGHTLY_ACTIVE,
              onTap: () => onLevelSelected(ActivityLevel.LIGHTLY_ACTIVE),
            ),
            const SizedBox(height: 16),
            _ActivityButton(
              title: 'Средняя активность',
              description: 'Умеренные тренировки 3-5 раз в неделю',
              isSelected: initialLevel == ActivityLevel.MODERATELY_ACTIVE,
              onTap: () => onLevelSelected(ActivityLevel.MODERATELY_ACTIVE),
            ),
            const SizedBox(height: 16),
            _ActivityButton(
              title: 'Высокая активность',
              description: 'Интенсивные тренировки 6-7 раз в неделю',
              isSelected: initialLevel == ActivityLevel.VERY_ACTIVE,
              onTap: () => onLevelSelected(ActivityLevel.VERY_ACTIVE),
            ),
            const SizedBox(height: 16),
            _ActivityButton(
              title: 'Профессиональный спорт',
              description: 'Несколько тренировок в день, физическая работа',
              isSelected: initialLevel == ActivityLevel.EXTREMELY_ACTIVE,
              onTap: () => onLevelSelected(ActivityLevel.EXTREMELY_ACTIVE),
            ),
          ],
        ),
      ),
      onNext: initialLevel != null 
        ? () { onLevelSelected(initialLevel!); }
        : null,
      onBack: onBack,
      nextButtonText: 'Завершить',
    );
  }
}

class _ActivityButton extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityButton({
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