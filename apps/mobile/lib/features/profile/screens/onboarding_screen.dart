import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/performance_service.dart';
import 'name_screen.dart';
import 'gender_screen.dart';
import 'birth_date_screen.dart';
import 'measurements_screen.dart';
import 'goal_screen.dart';
import 'activity_level_screen.dart';
import 'main_screen.dart';

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
  late final PerformanceService _performanceService;
  late Profile _profile;
  int _currentPage = 0;
  bool _isLoading = false;
  static const int _totalSteps = 6;

  // Накопитель изменений для батчевого обновления
  final Map<String, dynamic> _pendingUpdates = {};

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(userId: widget.userId);
    _performanceService = PerformanceService();
    _profile = widget.initialProfile ?? Profile();
    
    // Определяем, с какой страницы начать
    _currentPage = _getInitialPage();
    _pageController = PageController(initialPage: _currentPage);
    
    // Инициализируем сервис производительности
    _performanceService.initialize();
  }

  // Определяем начальную страницу на основе заполненности профиля
  int _getInitialPage() {
    // Проверяем каждое поле по порядку
    if (_profile.name == null || _profile.name!.isEmpty) return 0;
    if (_profile.gender == null) return 1;
    if (_profile.birthDate == null) return 2;
    if (_profile.height == null || _profile.weight == null) return 3;
    if (_profile.goal == null) return 4;
    if (_profile.activityLevel == null) return 5;
    return 5;
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
      // Отправляем все накопленные изменения одним запросом
      await _submitAllUpdates();
      
      // Переходим на основной экран
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userId: widget.userId),
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

  // Отправка всех накопленных изменений
  Future<void> _submitAllUpdates() async {
    if (_pendingUpdates.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.updateProfileBatch(_pendingUpdates);
      _pendingUpdates.clear();
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Обработка ошибок API
  void _handleError(dynamic error) {
    // Просто логируем ошибку, не показываем всплывашку
    print('Произошла ошибка: $error');
  }

  // Оптимизированный метод для обновления локального состояния
  void _updateLocalProfile(Profile updatedProfile, Map<String, dynamic> updates) {
    setState(() {
      _profile = updatedProfile;
      _pendingUpdates.addAll(updates);
    });
    _nextPage();
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
                  _updateLocalProfile(
                    _profile.copyWith(name: name),
                    {'name': name},
                  );
                },
                currentStep: _currentPage,
                totalSteps: _totalSteps,
              ),
              GenderScreen(
                initialGender: _profile.gender,
                onGenderSelected: (gender) {
                  _updateLocalProfile(
                    _profile.copyWith(gender: gender),
                    {'gender': gender.toString().split('.').last.toUpperCase()},
                  );
                },
                onBack: _previousPage,
                currentStep: _currentPage,
                totalSteps: _totalSteps,
              ),
              BirthDateScreen(
                initialDate: _profile.birthDate,
                onDateSelected: (date) {
                  _updateLocalProfile(
                    _profile.copyWith(birthDate: date),
                    {'birthDate': date.toIso8601String().split('T')[0]},
                  );
                },
                onBack: _previousPage,
                currentStep: _currentPage,
                totalSteps: _totalSteps,
              ),
              MeasurementsScreen(
                initialHeight: _profile.height,
                initialWeight: _profile.weight,
                onMeasurementsSubmitted: (height, weight) {
                  _updateLocalProfile(
                    _profile.copyWith(height: height, weight: weight),
                    {'height': height, 'weight': weight},
                  );
                },
                onBack: _previousPage,
                currentStep: _currentPage,
                totalSteps: _totalSteps,
              ),
              GoalScreen(
                initialGoal: _profile.goal,
                onGoalSelected: (goal) {
                  _updateLocalProfile(
                    _profile.copyWith(goal: goal),
                    {'goal': goal.name},
                  );
                },
                onBack: _previousPage,
                height: _profile.height,
                weight: _profile.weight,
                currentStep: _currentPage,
                totalSteps: _totalSteps,
              ),
              ActivityLevelScreen(
                initialLevel: _profile.activityLevel,
                onLevelSelected: (level) {
                  _updateLocalProfile(
                    _profile.copyWith(activityLevel: level),
                    {'activityLevel': level.name},
                  );
                },
                onBack: _previousPage,
                currentStep: _currentPage,
                totalSteps: _totalSteps,
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