import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/sleep_schedule_model.dart';
import 'sleep_service.dart';
import 'sleep_notification_service.dart';

/// Фоновый сервис для отслеживания времени сна
/// Максимально оптимизирован для энергоэффективности
class SleepBackgroundService {
  static const String _taskName = 'sleepTrackingTask';
  static const String _userIdKey = 'sleep_background_user_id';
  static const String _lastCheckKey = 'sleep_last_check_time';
  static const String _scheduleKey = 'sleep_cached_schedule';
  
  // Интервал проверки в минутах (оптимизировано для батареи)
  static const int _checkIntervalMinutes = 15;
  
  /// Инициализация фонового сервиса
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: _onStart,
        isForegroundMode: false,
        autoStartOnBoot: false,
      ),
    );
  }
  
  /// Запуск отслеживания для пользователя
  static Future<void> startTracking(String userId) async {
    try {
      // Сохраняем ID пользователя
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      
      // Загружаем и кэшируем расписание
      await _cacheSchedule(userId);
      
      // Запускаем фоновый сервис
      final service = FlutterBackgroundService();
      await service.startService();
      
      print('Фоновое отслеживание сна запущено для пользователя: $userId');
    } catch (e) {
      print('Ошибка запуска фонового отслеживания: $e');
    }
  }
  
  /// Остановка отслеживания
  static Future<void> stopTracking() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stop');
      
      // Очищаем кэш
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_scheduleKey);
      await prefs.remove(_lastCheckKey);
      
      print('Фоновое отслеживание сна остановлено');
    } catch (e) {
      print('Ошибка остановки фонового отслеживания: $e');
    }
  }
  
  /// Кэширование расписания для работы без интернета
  static Future<void> _cacheSchedule(String userId) async {
    try {
      final sleepService = SleepService(userId: userId);
      final schedule = await sleepService.getSleepSchedule();
      
      if (schedule != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_scheduleKey, jsonEncode(schedule.toJson()));
        debugPrint('Расписание сна кэшировано');
      }
    } catch (e) {
      debugPrint('Ошибка кэширования расписания: $e');
    }
  }
  
  /// Получение кэшированного расписания
  static Future<SleepSchedule?> _getCachedSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduleJson = prefs.getString(_scheduleKey);
      
      if (scheduleJson != null) {
        final scheduleData = jsonDecode(scheduleJson);
        return SleepSchedule.fromJson(scheduleData);
      }
    } catch (e) {
      debugPrint('Ошибка получения кэшированного расписания: $e');
    }
    return null;
  }
  
  /// Проверка, нужно ли показывать уведомление
  static Future<void> _checkBedtimeNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      
      if (userId == null) {
        debugPrint('Пользователь не найден для фонового отслеживания');
        return;
      }
      
      final schedule = await _getCachedSchedule();
      if (schedule == null || !schedule.isEnabled) {
        return;
      }
      
      final now = DateTime.now();
      
      // Проверяем, не проверяли ли мы недавно (для избежания дублирования)
      final lastCheck = prefs.getString(_lastCheckKey);
      if (lastCheck != null) {
        final lastCheckTime = DateTime.parse(lastCheck);
        if (now.difference(lastCheckTime).inMinutes < _checkIntervalMinutes) {
          return;
        }
      }
      
      // Обновляем время последней проверки
      await prefs.setString(_lastCheckKey, now.toIso8601String());
      
      // Определяем время засыпания на сегодня
      final bedtime = _calculateBedtime(schedule, now);
      if (bedtime == null) return;
      
      // Проверяем, нужно ли показать уведомление (за 30 минут до сна)
      final notificationTime = bedtime.subtract(Duration(minutes: 30));
      final timeDiff = now.difference(notificationTime).abs();
      
      // Показываем уведомление если время подошло (с погрешностью в рамках интервала проверки)
      if (timeDiff.inMinutes <= _checkIntervalMinutes && 
          now.isAfter(notificationTime) && 
          now.isBefore(bedtime.add(Duration(hours: 1)))) {
        
        // Инициализируем сервис уведомлений
        final notificationService = SleepNotificationService();
        await notificationService.initialize(userId);
        
        // Проверяем, не активен ли уже виджет сна
        final isWidgetActive = await notificationService.isSleepWidgetActive();
        if (!isWidgetActive) {
          await notificationService.showBedtimeWidget(bedtime);
          debugPrint('Показано уведомление о времени сна: $bedtime');
        }
      }
      
    } catch (e) {
      debugPrint('Ошибка проверки времени сна в фоне: $e');
    }
  }
  
  /// Расчет времени засыпания на основе расписания
  static DateTime? _calculateBedtime(SleepSchedule schedule, DateTime now) {
    try {
      // Получаем время пробуждения на завтра
      final tomorrow = now.add(Duration(days: 1));
      final tomorrowDayOfWeek = tomorrow.weekday % 7;
      final wakeTimeStr = schedule.getWakeTimeForDay(tomorrowDayOfWeek);
      
      if (wakeTimeStr == null) return null;
      
      // Парсим время пробуждения
      final wakeParts = wakeTimeStr.split(':');
      final wakeHour = int.parse(wakeParts[0]);
      final wakeMinute = int.parse(wakeParts[1]);
      
      // Рассчитываем время засыпания (предполагаем 8 часов сна)
      var bedtime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, wakeHour, wakeMinute)
          .subtract(Duration(hours: 8));
      
      // Если время засыпания уже прошло, берем на следующий день
      if (bedtime.isBefore(now)) {
        bedtime = bedtime.add(Duration(days: 1));
      }
      
      return bedtime;
    } catch (e) {
      debugPrint('Ошибка расчета времени засыпания: $e');
      return null;
    }
  }
  
  /// Обновление кэшированного расписания
  static Future<void> updateCachedSchedule(String userId) async {
    await _cacheSchedule(userId);
  }
  
  /// Проверка статуса фонового сервиса
  static Future<bool> isTrackingActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      return userId != null;
    } catch (e) {
      return false;
    }
  }
}

/// Обработчик для запуска фонового сервиса
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  try {
    debugPrint('Запуск фонового сервиса отслеживания сна');
    
    // Создаем таймер для периодической проверки (15 минут)
    Timer.periodic(Duration(minutes: 15), (timer) async {
      try {
        await SleepBackgroundService._checkBedtimeNotification();
      } catch (e) {
        debugPrint('Ошибка проверки времени сна: $e');
      }
    });
    
    // Обработка команд
    service.on('stop').listen((event) {
      service.stopSelf();
    });
    
  } catch (e) {
    debugPrint('Ошибка запуска фонового сервиса: $e');
  }
}

/// Обработчик для iOS в фоновом режиме
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  try {
    await SleepBackgroundService._checkBedtimeNotification();
    return true;
  } catch (e) {
    debugPrint('Ошибка фоновой задачи iOS: $e');
    return false;
  }
}
