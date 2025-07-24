import 'dart:async';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/performance_service.dart';
import '../services/performance_monitor.dart';
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

class _MainScreenState extends State<MainScreen> with PerformanceMonitorMixin {
  late final ProfileService _profileService;
  late final NutritionService _nutritionService;
  late final PerformanceService _performanceService;
  late final PerformanceMonitor _performanceMonitor;
  
  // Кэш для вычисленных данных
  Profile? _cachedProfile;
  DailySummary? _cachedDailySummary;
  String? _cachedAge;
  Map<String, dynamic>? _cachedNutritionData;
  
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasProfileLoadError = false; // Добавляем флаг для отслеживания ошибки загрузки профиля
  
  // Debounce для предотвращения частых обновлений
  Timer? _nutritionUpdateTimer;
  Timer? _profileUpdateTimer;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(userId: widget.userId);
    _nutritionService = NutritionService(userId: widget.userId);
    _performanceService = PerformanceService();
    _performanceMonitor = PerformanceMonitor();
    
    // Мониторинг уже инициализирован в main.dart
    _initializeServices();
  }

  @override
  void dispose() {
    _nutritionUpdateTimer?.cancel();
    _profileUpdateTimer?.cancel();
    _nutritionService.dispose();
    super.dispose();
  }

  // Инициализация сервисов с мониторингом
  Future<void> _initializeServices() async {
    if (_isInitialized) return;
    
    setState(() => _isLoading = true);
    
    try {
      await measureAsyncPerformance('Services initialization', () async {
        // Инициализируем сервис производительности
        await _performanceService.initialize();
        
        // Загружаем данные параллельно
        await Future.wait([
          _loadProfile(),
          _loadNutritionData(),
        ]);
      });
      
      _isInitialized = true;
      logMemoryUsage('After services initialization');
    } catch (e) {
      // Обрабатываем ошибки тихо
      debugPrint('Ошибка инициализации: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Загрузка профиля с кэшированием и мониторингом
  Future<void> _loadProfile() async {
    // Отменяем предыдущий таймер если он есть
    _profileUpdateTimer?.cancel();
    
    _profileUpdateTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final profile = await measureAsyncPerformance('Profile loading', () async {
          return await _profileService.getProfile();
        });
        
        if (mounted && profile != _cachedProfile) {
          _cachedProfile = profile;
          _hasProfileLoadError = false; // Сбрасываем флаг ошибки при успешной загрузке
          
          // Вычисляем возраст в изоляте с мониторингом
          if (profile.birthDate != null) {
            _cachedAge = await measureAsyncPerformance('Age calculation', () async {
              return await _performanceService.calculateAge(profile.birthDate);
            });
          }
          
          measurePerformance('Profile UI update', () {
            setState(() {});
          });
        }
      } catch (e) {
        debugPrint('Ошибка загрузки профиля: $e');
        // Устанавливаем флаг ошибки только если это не первоначальная загрузка
        if (mounted && _isInitialized) {
          setState(() {
            _hasProfileLoadError = true;
          });
        }
      }
    });
  }

  // Загрузка данных питания с кэшированием, debounce и мониторингом
  Future<void> _loadNutritionData() async {
    // Отменяем предыдущий таймер если он есть
    _nutritionUpdateTimer?.cancel();
    
    _nutritionUpdateTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final summary = await measureAsyncPerformance('Nutrition data loading', () async {
          return await _nutritionService.getTodaySummary();
        });
        
        if (mounted && summary != _cachedDailySummary) {
          _cachedDailySummary = summary;
          
          // Обрабатываем данные питания в изоляте с мониторингом
          if (_cachedProfile?.tdee != null) {
            _cachedNutritionData = await measureAsyncPerformance('Nutrition data processing', () async {
              return await _performanceService.processNutritionData(
                summary.totalCalories,
                _cachedProfile!.tdee!,
              );
            });
          }
          
          measurePerformance('Nutrition UI update', () {
            setState(() {});
          });
        }
      } catch (e) {
        // Обрабатываем ошибки тихо, используем пустую сводку как fallback
        if (mounted && _cachedDailySummary == null) {
          _cachedDailySummary = DailySummary(
            totalCalories: 0,
            totalProteins: 0,
            totalFats: 0,
            totalCarbs: 0,
          );
          setState(() {});
        }
      }
    });
  }

  // Оптимизированный виджет заголовка профиля с мониторингом
  Widget _buildProfileHeader(Profile profile) {
    return measurePerformance('Profile header build', () {
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
                    // Оптимизированная заглушка для фото
                    RepaintBoundary(
                      child: Container(
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
                            _cachedAge ?? 'Возраст не указан',
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
                  child: RepaintBoundary(
                    child: IconButton(
                      onPressed: () async {
                        final result = await measureAsyncPerformance('Edit profile navigation', () async {
                          return await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                userId: widget.userId,
                                initialProfile: profile,
                              ),
                            ),
                          );
                        });
                        
                        if (result == true) {
                          // Сбрасываем кэш и перезагружаем данные
                          _cachedProfile = null;
                          _cachedAge = null;
                          _cachedNutritionData = null;
                          _loadProfile();
                          _loadNutritionData();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Оптимизированный виджет прогресс-бара питания с мониторингом
  Widget _buildNutritionProgressBar(Profile profile) {
    return measurePerformance('Nutrition progress bar build', () {
      final targetCalories = profile.tdee ?? 2000.0;
      final consumedCalories = _cachedDailySummary?.totalCalories ?? 0.0;

      return RepaintBoundary(
        child: OptimizedNutritionProgressBar(
          consumedCalories: consumedCalories,
          targetCalories: targetCalories,
          nutritionData: _cachedNutritionData,
          onTap: () async {
            await measureAsyncPerformance('Nutrition screen navigation', () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NutritionScreen(userId: widget.userId),
                ),
              );
            });
            
            // Обновляем данные питания при возвращении
            _cachedDailySummary = null;
            _cachedNutritionData = null;
            _loadNutritionData();
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return measurePerformance('Main screen build', () {
      // Показываем индикатор загрузки во время инициализации
      if (_isLoading || !_isInitialized) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Показываем ошибку только если есть явная ошибка загрузки И система уже инициализирована
      if (_hasProfileLoadError && _cachedProfile == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Не удалось загрузить профиль',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasProfileLoadError = false;
                    });
                    _loadProfile();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      }

      // Если профиль еще не загружен, но нет ошибки - показываем загрузку
      if (_cachedProfile == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: CustomScrollView(
          // Оптимизация скроллинга
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildProfileHeader(_cachedProfile!),
            ),
            SliverToBoxAdapter(
              child: _buildNutritionProgressBar(_cachedProfile!),
            ),
            // Здесь будет остальной контент (активность и т.д.)
            const SliverFillRemaining(
              child: RepaintBoundary(
                child: Center(
                  child: Text(
                    'Здесь будет остальной контент',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Оптимизированный виджет прогресс-бара питания
class OptimizedNutritionProgressBar extends StatelessWidget {
  final double consumedCalories;
  final double targetCalories;
  final Map<String, dynamic>? nutritionData;
  final VoidCallback onTap;

  const OptimizedNutritionProgressBar({
    Key? key,
    required this.consumedCalories,
    required this.targetCalories,
    this.nutritionData,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Используем предвычисленные данные из изолята
    final percentage = nutritionData?['percentage'] ?? 0.0;
    final percentageInt = nutritionData?['percentageInt'] ?? 0;
    final colorName = nutritionData?['colorName'] ?? 'red';
    
    Color progressColor;
    switch (colorName) {
      case 'green':
        progressColor = Colors.green;
        break;
      case 'orange':
        progressColor = Colors.orange;
        break;
      default:
        progressColor = Colors.red;
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок блока
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Питание',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Информация о калориях
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${consumedCalories.toInt()} / ${targetCalories.toInt()} ккал',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$percentageInt%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Прогресс-бар
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 