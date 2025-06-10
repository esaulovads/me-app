import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'name_screen.dart';
import 'gender_screen.dart';
import 'birth_date_screen.dart';
import 'measurements_screen.dart';
import 'goal_screen.dart';
import 'activity_level_screen.dart';
import '../../nutrition/screens/nutrition_diary_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  final Profile? initialProfile;

  const OnboardingScreen({
    Key? key,
    required this.userId,
    this.initialProfile,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late final ProfileService _profileService;
  late Profile _profile;
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(userId: widget.userId);
    _profile = widget.initialProfile ?? Profile();
    
    // Определяем, с какой страницы начать
    _currentPage = _getInitialPage();
    _pageController = PageController(initialPage: _currentPage);
  }

  // Определяем начальную страницу на основе заполненности профиля
  int _getInitialPage() {
    // Проверяем каждое поле по порядку
    // Если поле не заполнено, возвращаем его индекс
    if (_profile.name == null || _profile.name!.isEmpty) return 0; // Имя
    if (_profile.gender == null) return 1; // Пол
    if (_profile.birthDate == null) return 2; // Дата рождения
    if (_profile.height == null || _profile.weight == null) return 3; // Рост и вес
    if (_profile.goal == null) return 4; // Цель
    if (_profile.activityLevel == null) return 5; // Уровень активности
    return 5; // Если все заполнено, показываем последний экран
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Переходим на экран дневника питания
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionDiaryScreen(userId: widget.userId),
          ),
        );
      }
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Обработка ошибок API
  void _handleError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Произошла ошибка: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Общий метод для обновления данных с индикатором загрузки
  Future<void> _updateProfile(Future<void> Function() updateFn) async {
    setState(() => _isLoading = true);
    try {
      await updateFn();
      _nextPage();
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              NameScreen(
                initialName: _profile.name,
                onNameSubmitted: (name) {
                  setState(() => _profile = _profile.copyWith(name: name));
                  _updateProfile(() => _profileService.updateName(name));
                },
              ),
              GenderScreen(
                initialGender: _profile.gender,
                onGenderSelected: (gender) {
                  setState(() => _profile = _profile.copyWith(gender: gender));
                  _updateProfile(() => _profileService.updateGender(gender));
                },
                onBack: _previousPage,
              ),
              BirthDateScreen(
                initialDate: _profile.birthDate,
                onDateSelected: (date) {
                  setState(() => _profile = _profile.copyWith(birthDate: date));
                  _updateProfile(() => _profileService.updateBirthDate(date));
                },
                onBack: _previousPage,
              ),
              MeasurementsScreen(
                initialHeight: _profile.height,
                initialWeight: _profile.weight,
                onMeasurementsSubmitted: (height, weight) async {
                  setState(() => _profile = _profile.copyWith(
                    height: height,
                    weight: weight,
                  ));
                  await _updateProfile(() async {
                    await _profileService.updateHeight(height);
                    await _profileService.updateWeight(weight);
                  });
                },
                onBack: _previousPage,
              ),
              GoalScreen(
                initialGoal: _profile.goal,
                onGoalSelected: (goal) {
                  setState(() => _profile = _profile.copyWith(goal: goal));
                  _updateProfile(() => _profileService.updateGoal(goal));
                },
                onBack: _previousPage,
                height: _profile.height,
                weight: _profile.weight,
              ),
              ActivityLevelScreen(
                initialLevel: _profile.activityLevel,
                onLevelSelected: (level) {
                  setState(() => _profile = _profile.copyWith(activityLevel: level));
                  _updateProfile(() => _profileService.updateActivityLevel(level));
                },
                onBack: _previousPage,
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
} 