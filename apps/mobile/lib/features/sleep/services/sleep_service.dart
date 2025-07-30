import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sleep_session_model.dart';
import '../models/sleep_schedule_model.dart';

/// Сервис для работы с данными сна
class SleepService {
  final String userId;
  static const String baseUrl = 'http://localhost:3003/sleep'; // Исправлен порт на 3003
  static const Duration timeoutDuration = Duration(seconds: 5); // Таймаут для запросов

  SleepService({required this.userId});

  /// Получает общую продолжительность сна за указанную дату
  Future<double> getTotalSleepDuration(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/duration?date=$date'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Микросервис возвращает продолжительность в минутах, конвертируем в часы
        final durationMinutes = data['totalDurationMinutes'] ?? 0;
        return durationMinutes / 60.0;
      } else {
        print('Ошибка получения продолжительности сна: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      print('Ошибка запроса продолжительности сна: $e');
      return 0.0;
    }
  }

  /// Получает все сессии сна за указанную дату
  Future<List<SleepSession>> getSleepSessionsByDate(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?date=$date'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SleepSession.fromJson(json)).toList();
      } else {
        print('Ошибка получения сессий сна: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Ошибка запроса сессий сна: $e');
      return [];
    }
  }

  /// Получает продолжительность сна за сегодня
  Future<double> getTodaySleepDuration() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return getTotalSleepDuration(today);
  }

  // === Методы для работы с расписанием сна ===

  /// Создает или обновляет расписание сна
  Future<SleepSchedule?> createOrUpdateSleepSchedule(CreateSleepScheduleDto dto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/schedule'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
        body: json.encode(dto.toJson()),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return SleepSchedule.fromJson(data);
      } else {
        print('Ошибка создания/обновления расписания сна: ${response.statusCode}');
        print('Ответ сервера: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Ошибка запроса создания/обновления расписания сна: $e');
      return null;
    }
  }

  /// Получает расписание сна пользователя
  Future<SleepSchedule?> getSleepSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedule'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Проверяем, есть ли сообщение о том, что расписание не настроено
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return null; // Расписание не настроено
        }
        
        return SleepSchedule.fromJson(data);
      } else if (response.statusCode == 404) {
        // Эндпоинт не найден - старая версия сервиса
        print('Эндпоинт расписания сна не найден - возможно, старая версия сервиса');
        return null;
      } else {
        print('Ошибка получения расписания сна: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка запроса расписания сна: $e');
      // Если это ошибка подключения, возвращаем null для graceful fallback
      return null;
    }
  }

  /// Обновляет расписание сна
  Future<SleepSchedule?> updateSleepSchedule(CreateSleepScheduleDto dto) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/schedule'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
        body: json.encode(dto.toJson()),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SleepSchedule.fromJson(data);
      } else {
        print('Ошибка обновления расписания сна: ${response.statusCode}');
        print('Ответ сервера: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Ошибка запроса обновления расписания сна: $e');
      return null;
    }
  }

  /// Удаляет расписание сна
  Future<bool> deleteSleepSchedule() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/schedule'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Ошибка удаления расписания сна: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ошибка запроса удаления расписания сна: $e');
      return false;
    }
  }

  /// Получает время пробуждения на конкретную дату согласно расписанию
  Future<String?> getWakeTimeForDate(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedule/wake-time?date=$date'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['wakeTime'] as String?;
      } else {
        print('Ошибка получения времени пробуждения: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка запроса времени пробуждения: $e');
      return null;
    }
  }

  /// Проверяет доступность сервиса расписания сна
  Future<bool> isScheduleServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedule'),
        headers: {
          'user-id': userId,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 3)); // Короткий таймаут для проверки

      // Если получили любой ответ (даже 404), значит сервис доступен
      return response.statusCode != null;
    } catch (e) {
      print('Сервис расписания сна недоступен: $e');
      return false;
    }
  }

  /// Освобождает ресурсы
  void dispose() {
    // Здесь можно добавить логику освобождения ресурсов если потребуется
  }
} 