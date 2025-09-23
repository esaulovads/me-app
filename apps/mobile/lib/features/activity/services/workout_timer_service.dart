import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workout_model.dart';
import 'activity_service.dart';

/// Глобальный сервис для управления таймером тренировок
class WorkoutTimerService extends ChangeNotifier {
  // Синглтон
  static WorkoutTimerService? _instance;
  static WorkoutTimerService get instance => _instance ??= WorkoutTimerService._internal();

  WorkoutTimerService._internal();

  // Текущая активная тренировка
  Workout? _activeWorkout;
  Workout? get activeWorkout => _activeWorkout;

  // Таймер для обновления времени
  Timer? _timer;
  
  // Время начала тренировки (для точного подсчета)
  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  // Текущая продолжительность тренировки в секундах
  int _currentDurationSeconds = 0;
  int get currentDurationSeconds => _currentDurationSeconds;

  // Состояние таймера
  bool get isRunning => _timer?.isActive ?? false;
  bool get hasActiveWorkout => _activeWorkout != null;

  // Сервис для API запросов
  ActivityService? _activityService;

  /// Инициализация сервиса
  void initialize(String userId) {
    _activityService = ActivityService.getInstance(userId: userId);
    _checkForActiveWorkout();
  }

  /// Проверка активной тренировки при запуске приложения
  Future<void> _checkForActiveWorkout() async {
    try {
      if (_activityService == null) return;
      
      final activeWorkout = await _activityService!.getActiveWorkout();
      if (activeWorkout != null && activeWorkout.isActive && activeWorkout.startedAt != null) {
        _activeWorkout = activeWorkout;
        _startTime = activeWorkout.startedAt;
        
        // Рассчитываем текущую продолжительность
        final now = DateTime.now();
        final durationMs = now.difference(_startTime!).inMilliseconds;
        _currentDurationSeconds = (durationMs / 1000).round();
        
        // Запускаем таймер
        _startTimer();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при проверке активной тренировки: $e');
    }
  }

  /// Начало тренировки
  Future<void> startWorkout(Workout workout) async {
    try {
      if (_activityService == null) {
        throw Exception('Сервис не инициализирован');
      }

      if (_activeWorkout != null) {
        throw Exception('У вас уже есть активная тренировка');
      }

      // Запускаем тренировку на бэкенде
      final updatedWorkout = await _activityService!.startWorkout(workout.id);
      
      _activeWorkout = updatedWorkout;
      _startTime = updatedWorkout.startedAt ?? DateTime.now();
      _currentDurationSeconds = 0;
      
      // Запускаем локальный таймер
      _startTimer();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при запуске тренировки: $e');
      rethrow;
    }
  }

  /// Завершение тренировки
  Future<Workout> finishWorkout() async {
    try {
      if (_activityService == null) {
        throw Exception('Сервис не инициализирован');
      }

      if (_activeWorkout == null) {
        throw Exception('Нет активной тренировки');
      }

      // Останавливаем локальный таймер
      _stopTimer();

      // Завершаем тренировку на бэкенде
      final finishedWorkout = await _activityService!.finishWorkout(_activeWorkout!.id);
      
      // Очищаем состояние
      _activeWorkout = null;
      _startTime = null;
      _currentDurationSeconds = 0;
      
      notifyListeners();
      
      return finishedWorkout;
    } catch (e) {
      debugPrint('Ошибка при завершении тренировки: $e');
      rethrow;
    }
  }

  /// Запуск локального таймера
  void _startTimer() {
    _stopTimer(); // Останавливаем предыдущий таймер если есть
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        final now = DateTime.now();
        final durationMs = now.difference(_startTime!).inMilliseconds;
        _currentDurationSeconds = (durationMs / 1000).round();
        notifyListeners();
      }
    });
  }

  /// Остановка локального таймера
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Форматированное время тренировки (чч:мм:сс)
  String get formattedTime {
    final hours = _currentDurationSeconds ~/ 3600;
    final minutes = (_currentDurationSeconds % 3600) ~/ 60;
    final seconds = _currentDurationSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// Продолжительность в минутах (для отображения в UI)
  int get durationInMinutes => (_currentDurationSeconds / 60).round();

  /// Принудительная остановка (например, при выходе из приложения)
  void forceStop() {
    _stopTimer();
    _activeWorkout = null;
    _startTime = null;
    _currentDurationSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  /// Глобальная очистка ресурсов
  static void globalDispose() {
    _instance?._stopTimer();
    _instance = null;
  }
}
