import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Сервис для управления разрешениями на уведомления
class NotificationPermissionService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Проверяет, есть ли разрешения на уведомления
  static Future<bool> hasNotificationPermissions() async {
    try {
      final android = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (android != null) {
        // Проверяем разрешения на уведомления
        final granted = await android.areNotificationsEnabled();
        return granted ?? false;
      }
      
      // Для iOS и других платформ считаем, что разрешения есть по умолчанию
      return true;
    } catch (e) {
      debugPrint('Ошибка проверки разрешений уведомлений: $e');
      return false;
    }
  }

  /// Запрашивает разрешения на уведомления с пользовательским диалогом
  static Future<bool> requestNotificationPermissions(BuildContext context) async {
    try {
      // Сначала проверяем, есть ли уже разрешения
      final hasPermissions = await hasNotificationPermissions();
      if (hasPermissions) {
        return true;
      }

      // Показываем диалог с объяснением
      final shouldRequest = await _showPermissionDialog(context);
      if (!shouldRequest) {
        return false;
      }

      return await _requestSystemPermissions();
    } catch (e) {
      debugPrint('Ошибка запроса разрешений уведомлений: $e');
      return false;
    }
  }

  /// Запрашивает разрешения напрямую от системы без диалога приложения
  static Future<bool> requestSystemPermissionsDirectly() async {
    try {
      // Сначала проверяем, есть ли уже разрешения
      final hasPermissions = await hasNotificationPermissions();
      if (hasPermissions) {
        return true;
      }

      return await _requestSystemPermissions();
    } catch (e) {
      debugPrint('Ошибка запроса системных разрешений уведомлений: $e');
      return false;
    }
  }

  /// Внутренний метод для запроса разрешений от системы
  static Future<bool> _requestSystemPermissions() async {
    try {
      final android = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (android != null) {
        // Запрашиваем разрешения
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Ошибка запроса системных разрешений: $e');
      return false;
    }
  }

  /// Показывает диалог с объяснением зачем нужны разрешения
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue),
              SizedBox(width: 8),
              Text('Разрешение на уведомления'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Для работы напоминаний о сне необходимо разрешение на отправку уведомлений.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Уведомления помогут:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.bedtime, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Напомнить о времени отхода ко сну')),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.alarm, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Отследить качество сна')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Пока нет'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Разрешить'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Показывает диалог с предложением включить уведомления в настройках
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Уведомления отключены'),
            ],
          ),
          content: const Text(
            'Чтобы получать напоминания о сне, включите уведомления в настройках приложения.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Понятно'),
            ),
          ],
        );
      },
    );
  }
}
