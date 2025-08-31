import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_schedule_model.dart';
import '../services/sleep_notification_service.dart';
import '../services/sleep_background_service.dart';

/// Виджет для управления отслеживанием сна
/// Интегрируется с экраном сна и обеспечивает удобное управление
class SleepTrackingWidget extends StatefulWidget {
  final String userId;
  final SleepSchedule? schedule;
  final VoidCallback? onScheduleNeeded;

  const SleepTrackingWidget({
    Key? key,
    required this.userId,
    this.schedule,
    this.onScheduleNeeded,
  }) : super(key: key);

  @override
  State<SleepTrackingWidget> createState() => _SleepTrackingWidgetState();
}

class _SleepTrackingWidgetState extends State<SleepTrackingWidget> {
  late SleepNotificationService _notificationService;
  bool _isTracking = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentSession;

  @override
  void initState() {
    super.initState();
    _notificationService = SleepNotificationService();
    _initializeServices();
  }

  /// Инициализация сервисов и проверка состояния
  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);
    
    try {
      // Инициализируем сервис уведомлений
      await _notificationService.initialize(widget.userId);
      
      // Проверяем состояние отслеживания
      _isTracking = await SleepBackgroundService.isTrackingActive();
      
      // Проверяем текущую сессию сна
      _currentSession = await _notificationService.getCurrentSleepSession();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Ошибка инициализации сервисов отслеживания сна: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Включение/отключение отслеживания
  Future<void> _toggleTracking() async {
    if (widget.schedule == null) {
      // Если расписание не настроено, предлагаем настроить
      widget.onScheduleNeeded?.call();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isTracking) {
        // Останавливаем отслеживание
        await SleepBackgroundService.stopTracking();
        await _notificationService.cancelAllSleepNotifications();
        
        setState(() {
          _isTracking = false;
          _currentSession = null;
        });
        
        _showSnackBar('Отслеживание сна отключено', Colors.orange);
      } else {
        // Запускаем отслеживание
        await SleepBackgroundService.startTracking(widget.userId);
        await _notificationService.scheduleBedtimeNotification(widget.schedule!);
        
        setState(() => _isTracking = true);
        
        _showSnackBar('Отслеживание сна включено', Colors.green);
      }
    } catch (e) {
      debugPrint('Ошибка переключения отслеживания: $e');
      _showSnackBar('Ошибка: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Показать snackbar с сообщением
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Тестирование уведомления (для отладки)
  Future<void> _testNotification() async {
    try {
      final now = DateTime.now();
      final testBedtime = now.add(const Duration(minutes: 1)); // Через минуту
      
      await _notificationService.showBedtimeWidget(testBedtime);
      _showSnackBar('Тестовое уведомление отправлено', Colors.blue);
    } catch (e) {
      _showSnackBar('Ошибка отправки уведомления: $e', Colors.red);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  _isTracking ? Icons.notifications_active : Icons.notifications_off,
                  color: _isTracking ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Отслеживание сна',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Описание функции
            Text(
              _isTracking 
                ? 'Виджет будет появляться в шторке уведомлений за 30 минут до времени сна'
                : 'Включите отслеживание для автоматических уведомлений о времени сна',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Информация о текущей сессии
            if (_currentSession != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bedtime, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Активная сессия сна',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Начата: ${_formatTime(DateTime.parse(_currentSession!['sleepTime']))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Кнопки управления
            Row(
              children: [
                // Основная кнопка включения/отключения
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.schedule != null ? _toggleTracking : null,
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTracking ? 'Отключить' : 'Включить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                // Кнопка тестирования (только в debug режиме)
                if (kDebugMode) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.bug_report),
                    tooltip: 'Тест уведомления',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ),
                ],
              ],
            ),
            
            // Предупреждение если расписание не настроено
            if (widget.schedule == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Расписание не настроено',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Настройте расписание сна для автоматических уведомлений',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onScheduleNeeded != null)
                      TextButton(
                        onPressed: widget.onScheduleNeeded,
                        child: const Text('Настроить'),
                      ),
                  ],
                ),
              ),
            ],
            
            // Дополнительная информация
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Как это работает:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('За 30 мин до сна', 'Виджет "пора спать" с кнопкой'),
                  _buildInfoRow('Нажали "ложусь спать"', 'Виджет "спокойной ночи"'),
                  _buildInfoRow('Нажали "я проснулся"', 'Сессия сна сохранена'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Создание строки с информацией
  Widget _buildInfoRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Форматирование времени для отображения
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
