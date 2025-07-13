import 'dart:async';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'edit_profile_screen.dart';
import '../../nutrition/widgets/nutrition_progress_bar.dart';
import '../../nutrition/services/nutrition_service.dart';
import '../../nutrition/models/meal_model.dart';
import '../../nutrition/nutrition_screen.dart';

class MainScreen extends StatefulWidget {
  final String userId;

  const MainScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final ProfileService _profileService;
  late final NutritionService _nutritionService;
  final _profileController = StreamController<Profile>();
  bool _isLoading = false;
  DailySummary? _dailySummary;
  
  // Debounce для предотвращения частых обновлений
  Timer? _nutritionUpdateTimer;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(userId: widget.userId);
    _nutritionService = NutritionService(userId: widget.userId);
    _loadProfile();
    _loadNutritionData();
  }

  @override
  void dispose() {
    _profileController.close();
    _nutritionService.dispose(); // Освобождаем ресурсы nutrition service
    _nutritionUpdateTimer?.cancel(); // Отменяем таймер обновления
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile();
      if (!_profileController.isClosed) {
        _profileController.add(profile);
      }
    } catch (e) {
      if (!_profileController.isClosed) {
        _profileController.addError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Загрузка данных питания за сегодня с debounce
  Future<void> _loadNutritionData() async {
    // Отменяем предыдущий таймер если он есть
    _nutritionUpdateTimer?.cancel();
    
    _nutritionUpdateTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final summary = await _nutritionService.getTodaySummary();
        if (mounted) {
          setState(() => _dailySummary = summary);
        }
      } catch (e) {
        // Обрабатываем ошибки тихо, используем пустую сводку как fallback
        if (mounted) {
          setState(() => _dailySummary = DailySummary(
            totalCalories: 0,
            totalProteins: 0,
            totalFats: 0,
            totalCarbs: 0,
          ));
        }
      }
    });
  }

  // Вычисляем возраст на основе даты рождения
  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 'Возраст не указан';
    
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    
    // Корректируем возраст если день рождения еще не наступил в этом году
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return '$age лет';
  }

  Widget _buildProfileHeader(Profile profile) {
    return RepaintBoundary(
      child: Container(
        height: MediaQuery.of(context).size.height / 3,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  // Заглушка для фото
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name ?? 'Имя не указано',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _calculateAge(profile.birthDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile.height != null && profile.weight != null)
                          Text(
                            '${profile.height!.toInt()} см, ${profile.weight!.toInt()} кг',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          userId: widget.userId,
                          initialProfile: profile,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadProfile();
                      // Обновляем данные питания, так как TDEE могла измениться
                      _loadNutritionData();
                    }
                  },
                  icon: const Icon(Icons.edit),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Создание виджета прогресс-бара питания
  Widget _buildNutritionProgressBar(Profile profile) {
    final targetCalories = profile.tdee ?? 2000.0; // Используем TDEE или значение по умолчанию
    final consumedCalories = _dailySummary?.totalCalories ?? 0.0;

    return NutritionProgressBar(
      consumedCalories: consumedCalories,
      targetCalories: targetCalories,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionScreen(userId: widget.userId),
          ),
        );
        // Обновляем данные питания при возвращении
        _loadNutritionData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Profile>(
        stream: _profileController.stream,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Не удалось загрузить профиль',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildProfileHeader(profile),
              ),
              SliverToBoxAdapter(
                child: _buildNutritionProgressBar(profile),
              ),
              // Здесь будет остальной контент (активность и т.д.)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Здесь будет остальной контент',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 