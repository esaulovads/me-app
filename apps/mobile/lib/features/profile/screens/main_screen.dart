import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/performance_service.dart';
import '../services/performance_monitor.dart';
import 'edit_profile_screen.dart';
import '../../nutrition/widgets/nutrition_progress_bar.dart';
import '../../nutrition/services/nutrition_service.dart';
import '../../nutrition/models/meal_model.dart';
import '../../nutrition/nutrition_screen.dart';
import '../../sleep/services/sleep_service.dart';
import '../../sleep/widgets/sleep_progress_bar.dart';
import '../../sleep/sleep_screen.dart';
import '../../activity/services/activity_service.dart';
import '../../activity/widgets/activity_progress_bar.dart';
import '../../activity/activity_screen.dart';
import '../../activity/models/workout_model.dart';

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
  late final SleepService _sleepService;
  late final ActivityService _activityService;
  late final PerformanceService _performanceService;
  late final PerformanceMonitor _performanceMonitor;
  
  // Кэш для вычисленных данных
  Profile? _cachedProfile;
  DailySummary? _cachedDailySummary;
  String? _cachedAge;
  Map<String, dynamic>? _cachedNutritionData;
  double? _cachedSleepDuration; // Кэш для продолжительности сна
  List<Workout>? _cachedTodaysWorkouts; // Кэш для сегодняшних тренировок
  
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasProfileLoadError = false; // Добавляем флаг для отслеживания ошибки загрузки профиля
  
  // Debounce для предотвращения частых обновлений
  Timer? _nutritionUpdateTimer;
  Timer? _profileUpdateTimer;
  Timer? _sleepUpdateTimer;
  Timer? _activityUpdateTimer;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(userId: widget.userId);
    _nutritionService = NutritionService(userId: widget.userId);
    _sleepService = SleepService(userId: widget.userId);
    _activityService = ActivityService(userId: widget.userId);
    _performanceService = PerformanceService();
    _performanceMonitor = PerformanceMonitor();
    
    // Очищаем кэш профиля чтобы получить обновленные данные со сна
    _profileService.clearCache();
    
    // Мониторинг уже инициализирован в main.dart
    _initializeServices();
  }

  bool _hasDidChangeDependenciesRunOnceBefore = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем данные сна только при первом запуске или явном возвращении на экран
    if (_isInitialized && !_hasDidChangeDependenciesRunOnceBefore) {
      _hasDidChangeDependenciesRunOnceBefore = true;
      // Задержка для предотвращения частых обновлений
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadSleepData();
        }
      });
    }
  }

  @override
  void dispose() {
    _nutritionUpdateTimer?.cancel();
    _profileUpdateTimer?.cancel();
    _sleepUpdateTimer?.cancel();
    _activityUpdateTimer?.cancel();
    _nutritionService.dispose();
    _sleepService.dispose();
    _activityService.dispose();
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
        
        // Загружаем только профиль сначала
        await _loadProfile();
        
        // Остальные данные загружаем после инициализации UI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _loadNutritionData();
            });
            
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) _loadSleepData();
            });
            
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) _loadActivityData();
            });
          }
        });
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
    
    _profileUpdateTimer = Timer(const Duration(milliseconds: 800), () async {
      try {
        final profile = await _profileService.getProfile();
        
        if (mounted && profile != _cachedProfile) {
          _cachedProfile = profile;
          _hasProfileLoadError = false; // Сбрасываем флаг ошибки при успешной загрузке
          
          // Вычисляем возраст в изоляте с мониторингом
          if (profile.birthDate != null) {
            _cachedAge = await _performanceService.calculateAge(profile.birthDate);
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
    
    _nutritionUpdateTimer = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final summary = await _nutritionService.getTodaySummary();
        
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

  // Загрузка данных активности с кэшированием и мониторингом
  Future<void> _loadActivityData() async {
    // Отменяем предыдущий таймер если он есть
    _activityUpdateTimer?.cancel();
    
    _activityUpdateTimer = Timer(const Duration(milliseconds: 1200), () async {
      try {
        final workouts = await _activityService.getTodaysWorkouts();
        
        if (mounted && workouts != _cachedTodaysWorkouts) {
          _cachedTodaysWorkouts = workouts;
          
          measurePerformance('Activity UI update', () {
            setState(() {});
          });
        }
      } catch (e) {
        // Обрабатываем ошибки тихо, используем пустой список как fallback
        if (mounted && _cachedTodaysWorkouts == null) {
          _cachedTodaysWorkouts = <Workout>[];
          setState(() {});
        }
      }
    });
  }

  // Запланированная асинхронная перезагрузка для разгрузки UI потока
  void _scheduleSmartReload() {
    // Используем microtask для выполнения в следующем цикле событий
    scheduleMicrotask(() async {
      await _smartReloadAfterProfileEdit();
    });
  }

  // Умная перезагрузка данных после редактирования профиля
  Future<void> _smartReloadAfterProfileEdit() async {
    try {
      // Сохраняем текущий профиль для сравнения
      final previousProfile = _cachedProfile;
      
      // Загружаем обновленный профиль без блокировки UI
      _cachedProfile = null;
      _cachedAge = null;
      
      // Ждем один фрейм для отрисовки UI
      await SchedulerBinding.instance.endOfFrame;
      await _loadProfile();
      
      // Проверяем, изменились ли поля, влияющие на расчеты питания
      final shouldReloadNutrition = previousProfile == null ||
          previousProfile.tdee != _cachedProfile?.tdee ||
          previousProfile.goal != _cachedProfile?.goal ||
          previousProfile.height != _cachedProfile?.height ||
          previousProfile.weight != _cachedProfile?.weight ||
          previousProfile.activityLevel != _cachedProfile?.activityLevel;
      
      // Проверяем, изменились ли поля, влияющие на рекомендации сна
      final shouldReloadSleep = previousProfile == null ||
          previousProfile.recommendedSleepDuration != _cachedProfile?.recommendedSleepDuration ||
          previousProfile.gender != _cachedProfile?.gender ||
          previousProfile.birthDate != _cachedProfile?.birthDate ||
          previousProfile.activityLevel != _cachedProfile?.activityLevel;
      
      // Перезагружаем только необходимые данные асинхронно
      if (shouldReloadNutrition) {
        _cachedDailySummary = null;
        _cachedNutritionData = null;
        _loadNutritionData(); // Запускаем асинхронно
      } else if (_cachedDailySummary == null) {
        // Если данные питания не были загружены, загружаем их
        _loadNutritionData(); // Запускаем асинхронно
      }
      
      if (shouldReloadSleep) {
        _cachedSleepDuration = null;
        _loadSleepData(); // Запускаем асинхронно
      } else if (_cachedSleepDuration == null) {
        // Если данные сна не были загружены, загружаем их
        _loadSleepData(); // Запускаем асинхронно
      }
      
      // Перезагружаем данные активности только при необходимости
      if (_cachedTodaysWorkouts == null) {
        _loadActivityData();
      }
      
      debugPrint('Умная перезагрузка: питание=${shouldReloadNutrition ? "обновлено" : "сохранено"}, сон=${shouldReloadSleep ? "обновлено" : "сохранено"}');
      
    } catch (e) {
      debugPrint('Ошибка умной перезагрузки: $e');
      // В случае ошибки выполняем полную перезагрузку
      _cachedProfile = null;
      _cachedAge = null;
      _cachedNutritionData = null;
      _cachedDailySummary = null;
      _cachedSleepDuration = null;
      _cachedTodaysWorkouts = null;
      _loadProfile();
      _loadNutritionData();
      _loadSleepData();
      _loadActivityData();
    }
  }

  // Загрузка данных сна с кэшированием и мониторингом
  Future<void> _loadSleepData() async {
    // Отменяем предыдущий таймер если он есть
    _sleepUpdateTimer?.cancel();
    
    _sleepUpdateTimer = Timer(const Duration(milliseconds: 1400), () async { // Увеличиваем debounce
      try {
        final sleepDuration = await _sleepService.getTodaySleepDuration();
        
        if (mounted && sleepDuration != _cachedSleepDuration) {
          _cachedSleepDuration = sleepDuration;
          
          measurePerformance('Sleep UI update', () {
            setState(() {});
          });
        }
      } catch (e) {
        // Обрабатываем ошибки тихо, используем 0 как fallback
        if (mounted && _cachedSleepDuration == null) {
          _cachedSleepDuration = 0.0;
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
                        // Быстрая навигация без мониторинга производительности  
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
                          // Асинхронная перезагрузка без блокировки UI
                          _scheduleSmartReload();
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

  // Оптимизированный виджет прогресс-бара сна с мониторингом
  Widget _buildSleepProgressBar(Profile profile) {
    return measurePerformance('Sleep progress bar build', () {
      final recommendedSleepHours = profile.recommendedSleepDuration ?? 8.0;
      final actualSleepHours = _cachedSleepDuration ?? 0.0;

      return RepaintBoundary(
        child: SleepProgressBar(
          actualSleepHours: actualSleepHours,
          recommendedSleepHours: recommendedSleepHours,
          onTap: () async {
            await measureAsyncPerformance('Sleep screen navigation', () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SleepScreen(userId: widget.userId),
                ),
              );
            });
            
            // Обновляем данные сна при возвращении
            _cachedSleepDuration = null;
            _loadSleepData();
          },
        ),
      );
    });
  }

  // Оптимизированный виджет прогресс-бара активности с мониторингом
  Widget _buildActivityProgressBar(Profile profile) {
    return measurePerformance('Activity progress bar build', () {
      final workouts = _cachedTodaysWorkouts ?? <Workout>[];
      final totalWeight = workouts.fold<double>(0.0, (sum, workout) => sum + workout.totalWeight);
      final targetWeight = 1000.0; // Целевой вес в кг (можно сделать настраиваемым)
      final totalWorkouts = workouts.length;

      return RepaintBoundary(
        child: ActivityProgressBar(
          totalWeight: totalWeight,
          targetWeight: targetWeight,
          totalWorkouts: totalWorkouts,
          onTap: () async {
            await measureAsyncPerformance('Activity screen navigation', () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityScreen(userId: widget.userId),
                ),
              );
            });
            
            // Обновляем данные активности при возвращении
            _cachedTodaysWorkouts = null;
            await _activityService.clearCache(); // Очищаем кэш для свежих данных
            _loadActivityData();
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
            SliverToBoxAdapter(
              child: _buildSleepProgressBar(_cachedProfile!),
            ),
            SliverToBoxAdapter(
              child: _buildActivityProgressBar(_cachedProfile!),
            ),
            // Небольшой отступ снизу
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
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
          child: Row(
            children: [
              // Иконка питания
              const Icon(
                Icons.restaurant,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 16),
              
              // Улучшенный прогресс-бар с автоматическим заполнением краев
              Expanded(
                child: _buildEnhancedProgressBar(percentage, progressColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Строит улучшенный прогресс-бар с автоматическим заполнением краев
  Widget _buildEnhancedProgressBar(double percentage, Color progressColor) {
    const double barHeight = 12.0;
    const double borderRadius = 6.0;
    const double edgeWidth = 8.0; // Ширина крайних областей
    
    // Определяем цвет левой области (всегда заполнена)
    Color leftEdgeColor = percentage > 0 ? progressColor : Colors.red;
    
    // Определяем цвет правой области (заполняется при 100%)
    Color rightEdgeColor = percentage >= 1.0 ? Colors.green : Colors.grey[200]!;
    
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Row(
          children: [
            // Левая область - всегда заполнена
            Container(
              width: edgeWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: leftEdgeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(borderRadius - 1),
                  bottomLeft: Radius.circular(borderRadius - 1),
                ),
              ),
            ),
            
            // Средняя область - динамически заполняется
            Expanded(
              child: Container(
                height: barHeight,
                color: Colors.grey[200],
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    color: progressColor,
                  ),
                ),
              ),
            ),
            
            // Правая область - заполняется при 100%
            Container(
              width: edgeWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: rightEdgeColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(borderRadius - 1),
                  bottomRight: Radius.circular(borderRadius - 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 