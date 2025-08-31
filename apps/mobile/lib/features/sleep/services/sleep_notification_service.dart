import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/sleep_schedule_model.dart';
import '../models/sleep_session_model.dart';
import 'sleep_service.dart';

/// Сервис для управления уведомлениями о сне
/// Оптимизирован для минимального энергопотребления
class SleepNotificationService {
  static final SleepNotificationService _instance = SleepNotificationService._internal();
  factory SleepNotificationService() => _instance;
  SleepNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // ID каналов уведомлений
  static const String _sleepChannelId = 'sleep_channel';
  static const String _sleepChannelName = 'Уведомления о сне';
  static const String _sleepChannelDescription = 'Уведомления о времени сна и пробуждения';
  
  // ID уведомлений
  static const int _bedtimeNotificationId = 100;
  static const int _sleepWidgetNotificationId = 101;
  
  // Ключи для SharedPreferences
  static const String _currentSleepSessionKey = 'current_sleep_session';
  static const String _sleepWidgetStateKey = 'sleep_widget_state';
  
  bool _isInitialized = false;
  String? _currentUserId;

  /// Инициализация сервиса уведомлений
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;
    
    _currentUserId = userId;
    
    // Инициализация timezone
    tz_data.initializeTimeZones();
    
    // Настройки для Android
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Настройки для iOS
    const DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Создаем канал уведомлений для Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannel();
      await _requestExactAlarmPermission();
    }
    
    _isInitialized = true;
  }
  
  /// Создание канала уведомлений для Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _sleepChannelId,
      _sleepChannelName,
      description: _sleepChannelDescription,
      importance: Importance.high,
      playSound: false, // Отключаем звук для экономии энергии
      enableVibration: false,
      enableLights: false,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  /// Запрос разрешения на точные уведомления для Android 12+
  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Проверяем, есть ли разрешение на точные уведомления
          final bool? hasPermission = await androidPlugin.canScheduleExactNotifications();
          
          if (hasPermission == false) {
            // Запрашиваем разрешение
            await androidPlugin.requestExactAlarmsPermission();
            debugPrint('Запрошено разрешение на точные уведомления');
          }
        }
      } catch (e) {
        debugPrint('Ошибка запроса разрешения на точные уведомления: $e');
        // Продолжаем работу без точных уведомлений
      }
    }
  }
  
  /// Обработка нажатий на уведомления
  void _onNotificationTapped(NotificationResponse response) async {
    // Проверяем actionId (для кнопок действий)
    if (response.actionId != null) {
      switch (response.actionId) {
        case 'go_to_sleep':
          await _handleGoToSleep();
          break;
        case 'wake_up':
          await _handleWakeUp();
          break;
      }
      return;
    }
    
    // Если actionId нет, проверяем payload
    final payload = response.payload;
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload);
      final action = data['action'] as String?;
      
      switch (action) {
        case 'go_to_sleep':
          await _handleGoToSleep();
          break;
        case 'wake_up':
          await _handleWakeUp();
          break;
      }
    } catch (e) {
      debugPrint('Ошибка обработки нажатия на уведомление: $e');
    }
  }
  
  /// Обработка кнопки "ложусь спать"
  Future<void> _handleGoToSleep() async {
    if (_currentUserId == null) return;
    
    try {
      final now = DateTime.now();
      
      // Сохраняем текущую сессию сна
      final sessionData = {
        'id': 'temp_${now.millisecondsSinceEpoch}',
        'userId': _currentUserId!,
        'sleepTime': now.toIso8601String(),
        'startedAt': now.toIso8601String(),
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSleepSessionKey, jsonEncode(sessionData));
      
      // Получаем расписание для определения времени пробуждения
      final sleepService = SleepService(userId: _currentUserId!);
      final schedule = await sleepService.getSleepSchedule();
      
      String? wakeTimeStr;
      if (schedule != null) {
        // Получаем время пробуждения на завтра
        final tomorrow = now.add(const Duration(days: 1));
        final dayOfWeek = tomorrow.weekday % 7; // Преобразуем в 0-6 формат
        wakeTimeStr = schedule.getWakeTimeForDay(dayOfWeek);
      } else {
        // Если расписания нет, устанавливаем время пробуждения через 8 часов
        final defaultWakeTime = now.add(const Duration(hours: 8));
        wakeTimeStr = '${defaultWakeTime.hour.toString().padLeft(2, '0')}:${defaultWakeTime.minute.toString().padLeft(2, '0')}';
      }
      
      // Сначала отменяем текущие уведомления
      await _notifications.cancel(_sleepWidgetNotificationId);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Показываем виджет "спокойной ночи"
      await showSleepingWidget(wakeTimeStr);
      
    } catch (e) {
      debugPrint('Ошибка при засыпании: $e');
    }
  }
  
  /// Обработка кнопки "я проснулся"
  Future<void> _handleWakeUp() async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_currentSleepSessionKey);
      
      if (sessionData != null) {
        final session = jsonDecode(sessionData);
        final sleepTime = DateTime.parse(session['sleepTime']);
        final wakeTime = DateTime.now();
        
        // Создаем сессию сна через API
        final sleepService = SleepService(userId: _currentUserId!);
        await sleepService.createSleepSession(
          sleepTime: sleepTime,
          wakeTime: wakeTime,
        );
        
        // Очищаем временные данные
        await prefs.remove(_currentSleepSessionKey);
        await prefs.remove(_sleepWidgetStateKey);
      }
      
      // Скрываем виджет
      await _notifications.cancel(_sleepWidgetNotificationId);
      
    } catch (e) {
      debugPrint('Ошибка при пробуждении: $e');
    }
  }
  
  /// Запланировать уведомление о времени сна
  Future<void> scheduleBedtimeNotification(SleepSchedule schedule) async {
    if (!_isInitialized || _currentUserId == null) return;
    
    // Отменяем предыдущие уведомления
    await _notifications.cancel(_bedtimeNotificationId);
    
    // Определяем время уведомления (за 30 минут до сна)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Получаем время пробуждения на завтра для расчета времени сна
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDayOfWeek = tomorrow.weekday % 7;
    final wakeTimeStr = schedule.getWakeTimeForDay(tomorrowDayOfWeek);
    
    if (wakeTimeStr == null) return;
    
    // Парсим время пробуждения
    final wakeParts = wakeTimeStr.split(':');
    final wakeHour = int.parse(wakeParts[0]);
    final wakeMinute = int.parse(wakeParts[1]);
    
    // Рассчитываем время засыпания (предполагаем 8 часов сна)
    var sleepDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, wakeHour, wakeMinute)
        .subtract(const Duration(hours: 8));
    
    // Если время сна уже прошло, планируем на следующий день
    if (sleepDateTime.isBefore(now)) {
      sleepDateTime = sleepDateTime.add(const Duration(days: 1));
    }
    
    // Время уведомления - за 30 минут до сна
    final notificationTime = sleepDateTime.subtract(const Duration(minutes: 30));
    
    // Планируем уведомление только если оно в будущем
    if (notificationTime.isAfter(now)) {
      await _scheduleBedtimeAlert(notificationTime, sleepDateTime);
    }
  }
  
  /// Запланировать предупреждение о времени сна
  Future<void> _scheduleBedtimeAlert(DateTime notificationTime, DateTime bedtime) async {
    final timeStr = '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';
    
    try {
      await _notifications.zonedSchedule(
        _bedtimeNotificationId,
        'Скоро время спать! 🌙',
        'Рекомендуемое время засыпания: $timeStr',
        tz.TZDateTime.from(notificationTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _sleepChannelId,
            _sleepChannelName,
            channelDescription: _sleepChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            ongoing: false,
            autoCancel: true,
            actions: [
              const AndroidNotificationAction(
                'go_to_sleep',
                'Ложусь спать',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        payload: jsonEncode({
          'action': 'bedtime_alert',
          'bedtime': bedtime.toIso8601String(),
        }),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Ошибка планирования уведомления: $e');
      // Если не получается запланировать точное уведомление, 
      // показываем обычное уведомление немедленно (если время подошло)
      final now = DateTime.now();
      if (notificationTime.isBefore(now) && bedtime.isAfter(now)) {
        await showBedtimeWidget(bedtime);
      }
    }
  }
  
  /// Показать виджет в шторке уведомлений во время сна
  Future<void> showSleepingWidget(String? wakeTimeStr) async {
    final wakeTimeDisplay = wakeTimeStr != null 
        ? 'Пробуждение в $wakeTimeStr' 
        : 'Время пробуждения не установлено';
    
    try {
      await _notifications.show(
        _sleepWidgetNotificationId,
        'Спокойной ночи! 😴',
        wakeTimeDisplay,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _sleepChannelId,
            _sleepChannelName,
            channelDescription: _sleepChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            ongoing: true, // Уведомление не исчезает при свайпе
            autoCancel: false,
            actions: [
              const AndroidNotificationAction(
                'wake_up',
                'Я проснулся',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        payload: jsonEncode({
          'action': 'sleeping',
          'wakeTime': wakeTimeStr,
        }),
      );
      
      // Сохраняем состояние виджета
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sleepWidgetStateKey, jsonEncode({
        'isActive': true,
        'showTime': DateTime.now().toIso8601String(),
        'wakeTime': wakeTimeStr,
      }));
      
    } catch (e) {
      debugPrint('Ошибка показа виджета "спокойной ночи": $e');
      rethrow;
    }
  }
  
  /// Показать виджет "пора спать"
  Future<void> showBedtimeWidget(DateTime bedtime) async {
    if (!_isInitialized) return;
    
    final timeStr = '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}';
    
    try {
      await _notifications.show(
        _sleepWidgetNotificationId,
        'Пора спать! 🌙',
        'Рекомендуемое время засыпания: $timeStr',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _sleepChannelId,
            _sleepChannelName,
            channelDescription: _sleepChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            autoCancel: false,
            actions: [
              const AndroidNotificationAction(
                'go_to_sleep',
                'Ложусь спать',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        payload: jsonEncode({
          'action': 'bedtime_widget',
          'bedtime': bedtime.toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Ошибка отправки уведомления: $e');
      rethrow;
    }
  }
  
  /// Отменить все уведомления о сне
  Future<void> cancelAllSleepNotifications() async {
    await _notifications.cancel(_bedtimeNotificationId);
    await _notifications.cancel(_sleepWidgetNotificationId);
    
    // Очищаем сохраненные данные
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSleepSessionKey);
    await prefs.remove(_sleepWidgetStateKey);
  }
  
  /// Проверить, активен ли виджет сна
  Future<bool> isSleepWidgetActive() async {
    final prefs = await SharedPreferences.getInstance();
    final widgetState = prefs.getString(_sleepWidgetStateKey);
    if (widgetState == null) return false;
    
    try {
      final state = jsonDecode(widgetState);
      return state['isActive'] == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Получить текущую сессию сна
  Future<Map<String, dynamic>?> getCurrentSleepSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString(_currentSleepSessionKey);
    if (sessionData == null) return null;
    
    try {
      return jsonDecode(sessionData);
    } catch (e) {
      return null;
    }
  }
  
  /// Освобождение ресурсов
  void dispose() {
    // Тут ничего особенного делать не нужно
    // Уведомления продолжат работать в фоне
  }
}
