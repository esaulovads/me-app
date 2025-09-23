import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/workout_schedule_model.dart';
import '../models/muscle_group_model.dart';

/// Сервис для работы с расписанием тренировок
class WorkoutScheduleService {
  // Определяем URL в зависимости от платформы
  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3004'; // Для Android эмулятора
    } else if (Platform.isIOS) {
      return 'http://localhost:3004'; // Для iOS симулятора
    } else {
      return 'http://localhost:3004'; // Для desktop
    }
  }
  final String userId;
  
  // Таймауты для запросов
  static const Duration _timeout = Duration(seconds: 10);
  
  // Кэширование
  List<MuscleGroup>? _cachedMuscleGroups;
  DateTime? _muscleGroupsCacheTime;
  WorkoutSchedule? _cachedTodayWorkout;
  DateTime? _todayWorkoutCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  WorkoutScheduleService({required this.userId});

  /// Получить все группы мышц
  Future<List<MuscleGroup>> getMuscleGroups() async {
    // Проверяем кэш
    if (_cachedMuscleGroups != null && 
        _muscleGroupsCacheTime != null && 
        DateTime.now().difference(_muscleGroupsCacheTime!) < _cacheTimeout) {
      return _cachedMuscleGroups!;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/muscle-groups'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final groups = data.map((json) => MuscleGroup.fromJson(json)).toList();
        
        // Кэшируем результат
        _cachedMuscleGroups = groups;
        _muscleGroupsCacheTime = DateTime.now();
        
        return groups;
      } else {
        throw Exception('Не удалось загрузить группы мышц: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Ошибка сети при загрузке групп мышц: $e');
    } on FormatException catch (e) {
      throw Exception('Ошибка формата данных: $e');
    } catch (e) {
      throw Exception('Ошибка загрузки групп мышц: $e');
    }
  }

  /// Получить расписание пользователя на всю неделю
  Future<List<WorkoutSchedule>> getUserSchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workout-schedule/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WorkoutSchedule.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить расписание: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Ошибка сети при загрузке расписания: $e');
    } on FormatException catch (e) {
      throw Exception('Ошибка формата данных: $e');
    } catch (e) {
      throw Exception('Ошибка загрузки расписания: $e');
    }
  }

  /// Получить тренировку на сегодня
  Future<WorkoutSchedule?> getTodayWorkout() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/workout-schedule/user/$userId/today'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return data != null ? WorkoutSchedule.fromJson(data) : null;
      } else if (response.statusCode == 404) {
        return null; // Нет тренировки на сегодня
      } else {
        throw Exception('Не удалось загрузить тренировку на сегодня: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      // Если сервис недоступен, просто возвращаем null вместо ошибки
      print('Сервис расписания недоступен: $e');
      return null;
    } on FormatException catch (e) {
      throw Exception('Ошибка формата данных: $e');
    } catch (e) {
      // Для других ошибок тоже возвращаем null, чтобы не блокировать основной функционал
      print('Ошибка загрузки тренировки на сегодня: $e');
      return null;
    }
  }

  /// Обновить расписание для дня
  Future<WorkoutSchedule> updateScheduleForDay({
    required int dayOfWeek,
    String? muscleGroupId,
    bool? isFullBody,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (muscleGroupId != null) body['muscleGroupId'] = muscleGroupId;
      if (isFullBody != null) body['isFullBody'] = isFullBody;
      if (isActive != null) body['isActive'] = isActive;

      final response = await http.put(
        Uri.parse('$_baseUrl/workout-schedule/user/$userId/day/$dayOfWeek'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return WorkoutSchedule.fromJson(data);
      } else {
        throw Exception('Не удалось обновить расписание: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Ошибка сети при обновлении расписания: $e');
    } on FormatException catch (e) {
      throw Exception('Ошибка формата данных: $e');
    } catch (e) {
      throw Exception('Ошибка обновления расписания: $e');
    }
  }

  /// Удалить расписание для дня (сделать день отдыха)
  Future<void> removeScheduleForDay(int dayOfWeek) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/workout-schedule/user/$userId/day/$dayOfWeek'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Не удалось удалить расписание: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Ошибка сети при удалении расписания: $e');
    } catch (e) {
      throw Exception('Ошибка удаления расписания: $e');
    }
  }
}
