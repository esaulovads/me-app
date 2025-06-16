import 'package:flutter/material.dart';
import 'onboarding_button.dart';
import 'onboarding_progress.dart';

// Общий layout для всех экранов онбординга
class OnboardingLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String nextButtonText;
  final bool isLastStep;
  final int currentStep;
  final int totalSteps;

  const OnboardingLayout({
    Key? key,
    required this.title,
    required this.child,
    required this.onNext,
    this.onBack,
    this.nextButtonText = 'Далее',
    this.isLastStep = false,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingProgress(
                currentStep: currentStep,
                totalSteps: totalSteps,
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(child: child),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onBack != null) ...[
                    Expanded(
                      child: OnboardingButton(
                        text: 'Назад',
                        onPressed: onBack!,
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: OnboardingButton(
                      text: nextButtonText,
                      onPressed: onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 