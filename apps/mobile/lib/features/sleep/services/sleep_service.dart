import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sleep_session_model.dart';

/// Сервис для работы с данными сна
class SleepService {
  final String userId;
  static const String baseUrl = 'http://localhost:3007/sleep'; // Порт микросервиса сна

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
      );

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
      );

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

  /// Освобождает ресурсы
  void dispose() {
    // Здесь можно добавить логику освобождения ресурсов если потребуется
  }
} 