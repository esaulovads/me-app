import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';
import '../models/workout_model.dart';

/// Сервис для работы с API активности
class ActivityService {
  // Синглтон
  static ActivityService? _instance;
  static ActivityService getInstance({required String userId}) {
    _instance ??= ActivityService._internal(userId);
    return _instance!;
  }

  final String userId;
  
  // Оптимизированный HTTP клиент с connection pooling
  static http.Client _httpClient = http.Client();
  
  // Счетчик ошибок соединения для пересоздания клиента
  static int _connectionErrors = 0;
  static const int _maxConnectionErrors = 3;
  
  // Максимальное количество повторных попыток
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  
  // В Android эмуляторе localhost это 10.0.2.2
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3004';
    }
    return 'http://10.0.2.2:3004'; // Для Android эмулятора
  }

  // Кэш для данных активности с TTL
  static final Map<String, _CacheEntry<List<Workout>>> _workoutsCache = {};
  static final Map<String, _CacheEntry<List<Exercise>>> _exercisesCache = {};
  static final Map<String, _CacheEntry<WorkoutStatistics>> _statisticsCache = {};
  
  // TTL для кэшей - увеличиваем для лучшей производительности
  static const Duration _cacheShortTTL = Duration(minutes: 10);
  static const Duration _cacheLongTTL = Duration(minutes: 30);
  
  // Таймер для автоочистки кэша
  static Timer? _cacheCleanupTimer;
  
  // Инициализация автоочистки кэша
  static void _initCacheCleanup() {
    _cacheCleanupTimer ??= Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredCache();
    });
  }
  
  // Пересоздание HTTP клиента при проблемах с соединением
  static void _recreateHttpClient() {
    _httpClient.close();
    _httpClient = http.Client();
    _connectionErrors = 0;
    print('HTTP клиент пересоздан из-за ошибок соединения');
  }
  
  // Обработка ошибки соединения
  static void _handleConnectionError() {
    _connectionErrors++;
    if (_connectionErrors >= _maxConnectionErrors) {
      _recreateHttpClient();
    }
  }
  
  // Очистка просроченного кэша
  static void _cleanupExpiredCache() {
    final now = DateTime.now();
    
    _workoutsCache.removeWhere((key, entry) => entry.isExpired(now));
    _exercisesCache.removeWhere((key, entry) => entry.isExpired(now));
    _statisticsCache.removeWhere((key, entry) => entry.isExpired(now));
  }
  
  // Debounce для предотвращения множественных запросов
  Timer? _debounceTimer;
  
  // Оптимизированные таймауты
  static const Duration _shortTimeout = Duration(seconds: 5);
  static const Duration _mediumTimeout = Duration(seconds: 8);
  static const Duration _longTimeout = Duration(seconds: 12);

  // Приватный конструктор
  ActivityService._internal(this.userId) {
    _initCacheCleanup(); // Инициализируем автоочистку кэша
  }

  // Устаревший конструктор для обратной совместимости
  factory ActivityService({required String userId}) {
    return getInstance(userId: userId);
  }

  // Оптимизированные общие заголовки
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'user-id': userId,
  };

  // Оптимизированный HTTP GET запрос
  Future<http.Response> _get(String url, {Duration? timeout}) async {
    return _httpClient.get(
      Uri.parse(url),
      headers: _headers,
    ).timeout(timeout ?? _mediumTimeout);
  }

  // Оптимизированный HTTP POST запрос
  Future<http.Response> _post(String url, {required String body, Duration? timeout}) async {
    return _httpClient.post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    ).timeout(timeout ?? _mediumTimeout);
  }

  // Оптимизированный HTTP PUT запрос
  Future<http.Response> _put(String url, {required String body, Duration? timeout}) async {
    return _httpClient.put(
      Uri.parse(url),
      headers: _headers,
      body: body,
    ).timeout(timeout ?? _mediumTimeout);
  }

  // Оптимизированный HTTP DELETE запрос
  Future<http.Response> _delete(String url, {Duration? timeout}) async {
    return _httpClient.delete(
      Uri.parse(url),
      headers: _headers,
    ).timeout(timeout ?? _mediumTimeout);
  }

  // Выполнение HTTP запроса с retry логикой
  Future<http.Response> _executeWithRetry(Future<http.Response> Function() request) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        final response = await request();
        _connectionErrors = 0; // Сбрасываем счетчик при успехе
        return response;
      } on SocketException catch (e) {
        attempts++;
        print('SocketException (attempt $attempts/$_maxRetries): $e');
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay * attempts);
      } on http.ClientException catch (e) {
        attempts++;
        print('ClientException (attempt $attempts/$_maxRetries): $e');
        _handleConnectionError();
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay * attempts);
      } on TimeoutException catch (e) {
        attempts++;
        print('TimeoutException (attempt $attempts/$_maxRetries): $e');
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay * attempts);
      }
    }
    throw Exception('Max retries exceeded');
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С УПРАЖНЕНИЯМИ ===

  /// Получение списка упражнений с пагинацией и поиском
  Future<ExercisesResponse> getExercises({
    int limit = 50,
    int offset = 0,
    String? search,
    String? muscleGroup,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        params['muscleGroup'] = muscleGroup;
      }

      final url = Uri.parse('$baseUrl/exercises').replace(queryParameters: params);
      
      final response = await _executeWithRetry(() => _get(url.toString()));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ExercisesResponse.fromJson(data);
      } else {
        throw Exception('Ошибка загрузки упражнений: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  /// Получение списка всех уникальных групп мышц
  Future<List<String>> getMuscleGroups() async {
    try {
      final url = Uri.parse('$baseUrl/exercises/muscle-groups');
      
      final response = await _executeWithRetry(() => _get(url.toString()));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((group) => group as String).toList();
      } else {
        throw Exception('Ошибка загрузки групп мышц: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С ТРЕНИРОВКАМИ ===

  /// Начало тренировки (запуск таймера)
  Future<Workout> startWorkout(String workoutId) async {
    try {
      final url = Uri.parse('$baseUrl/workouts/$workoutId/start');
      
      final response = await _executeWithRetry(() => _post(url.toString(), body: '{}'));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final workout = Workout.fromJson(data);
        
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
        
        return workout;
      } else {
        throw Exception('Ошибка начала тренировки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  /// Завершение тренировки (остановка таймера)
  Future<Workout> finishWorkout(String workoutId) async {
    try {
      final url = Uri.parse('$baseUrl/workouts/$workoutId/finish');
      
      final response = await _executeWithRetry(() => _post(url.toString(), body: '{}'));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final workout = Workout.fromJson(data);
        
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
        
        return workout;
      } else {
        throw Exception('Ошибка завершения тренировки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  /// Получение активной тренировки пользователя
  Future<Workout?> getActiveWorkout() async {
    try {
      final url = Uri.parse('$baseUrl/workouts/active/current');
      
      final response = await _executeWithRetry(() => _get(url.toString()));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Workout.fromJson(data);
      } else if (response.statusCode == 404) {
        // Нет активной тренировки - это нормально
        return null;
      } else {
        throw Exception('Ошибка получения активной тренировки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Создание новой тренировки
  Future<Workout> createWorkout({
    required DateTime date,
    int? duration,
    List<String>? targetMuscleGroups,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/workouts');
      
      final body = json.encode({
        'date': _formatDate(date),
        'duration': duration ?? 0, // По умолчанию 0, будет обновляться автоматически
        'targetMuscleGroups': targetMuscleGroups ?? [],
      });

      final response = await _executeWithRetry(() => _post(url.toString(), body: body));

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final workout = Workout.fromJson(data);
        
        // Очищаем кэш для обновления данных
        clearCacheForDate(date);
        
        return workout;
      } else {
        throw Exception('Ошибка создания тренировки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  /// Получение тренировок за конкретный день
  Future<List<Workout>> getWorkoutsByDate(DateTime date) async {
    final dateString = _formatDate(date);
    final cacheKey = '${userId}_$dateString';
    
    // Проверяем кэш
    if (_workoutsCache.containsKey(cacheKey)) {
      return _workoutsCache[cacheKey]!.value;
    }

    try {
      final url = Uri.parse('$baseUrl/workouts/by-date?date=$dateString');
      
      final response = await _executeWithRetry(() => _get(url.toString()));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final workouts = data.map((workoutJson) => Workout.fromJson(workoutJson)).toList();
        
        // Кэшируем результат
        _workoutsCache[cacheKey] = _CacheEntry(workouts, DateTime.now().add(_cacheShortTTL));
        return workouts;
      } else if (response.statusCode == 404) {
        // 404 означает, что данных нет - это нормально, возвращаем пустой список
        final emptyWorkouts = <Workout>[];
        _workoutsCache[cacheKey] = _CacheEntry(emptyWorkouts, DateTime.now().add(_cacheShortTTL));
        return emptyWorkouts;
      } else {
        throw Exception('Ошибка загрузки тренировок: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      print('Ошибка в getWorkoutsByDate: $e');
      if (e.toString().contains('404')) {
        // 404 - нормальная ситуация, возвращаем пустой список
        final emptyWorkouts = <Workout>[];
        _workoutsCache[cacheKey] = _CacheEntry(emptyWorkouts, DateTime.now().add(_cacheShortTTL));
        return emptyWorkouts;
      }
      rethrow;
    }
  }

  /// Получение тренировок за сегодня
  Future<List<Workout>> getTodaysWorkouts() async {
    return getWorkoutsByDate(DateTime.now());
  }

  /// Получение статистики тренировок
  Future<WorkoutStatistics> getWorkoutStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final cacheKey = '${userId}_${startDate?.toString() ?? 'all'}_${endDate?.toString() ?? 'all'}';
    
    // Проверяем кэш
    if (_statisticsCache.containsKey(cacheKey)) {
      return _statisticsCache[cacheKey]!.value;
    }

    try {
      final params = <String, String>{};
      if (startDate != null) {
        params['startDate'] = _formatDate(startDate);
      }
      if (endDate != null) {
        params['endDate'] = _formatDate(endDate);
      }

      final url = Uri.parse('$baseUrl/workouts/statistics').replace(queryParameters: params);
      
      final response = await _executeWithRetry(() => _get(url.toString()));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final statistics = WorkoutStatistics.fromJson(data);
        
        // Кэшируем результат
        _statisticsCache[cacheKey] = _CacheEntry(statistics, DateTime.now().add(_cacheLongTTL));
        return statistics;
      } else {
        throw Exception('Ошибка загрузки статистики: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  /// Удаление тренировки
  Future<void> deleteWorkout(String workoutId, DateTime workoutDate) async {
    try {
      final url = Uri.parse('$baseUrl/workouts/$workoutId');
      
      final response = await _executeWithRetry(() => _delete(url.toString()));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Очищаем кэш для даты тренировки
        clearCacheForDate(workoutDate);
      } else {
        throw Exception('Ошибка удаления тренировки: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteWorkout: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С УПРАЖНЕНИЯМИ В ТРЕНИРОВКЕ ===

  /// Добавление упражнения в тренировку
  Future<void> addExerciseToWorkout(String workoutId, String exerciseId) async {
    try {
      final url = Uri.parse('$baseUrl/workout-exercises');
      
      final body = json.encode({
        'workoutId': workoutId,
        'exerciseId': exerciseId,
      });

      final response = await _executeWithRetry(() => _post(url.toString(), body: body));

      if (response.statusCode == 201) {
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
      } else {
        throw Exception('Ошибка добавления упражнения: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addExerciseToWorkout: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  /// Получение упражнений конкретной тренировки
  Future<List<WorkoutExercise>> getWorkoutExercises(String workoutId) async {
    try {
      final url = Uri.parse('$baseUrl/workout-exercises/by-workout/$workoutId');
      
      final response = await _executeWithRetry(() => _get(url.toString()));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((exerciseJson) => WorkoutExercise.fromJson(exerciseJson)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Ошибка загрузки упражнений тренировки: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      if (e.toString().contains('404')) {
        return [];
      }
      rethrow;
    }
  }

  /// Удаление упражнения из тренировки
  Future<void> removeExerciseFromWorkout(String workoutExerciseId) async {
    try {
      final url = Uri.parse('$baseUrl/workout-exercises/$workoutExerciseId');
      
      final response = await _executeWithRetry(() => _delete(url.toString()));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
      } else {
        throw Exception('Ошибка удаления упражнения: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in removeExerciseFromWorkout: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С ПОДХОДАМИ ===

  /// Создание подхода
  Future<WorkoutSet> createSet({
    required String workoutExerciseId,
    required int reps,
    required double weight,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/sets');
      
      final body = json.encode({
        'workoutExerciseId': workoutExerciseId,
        'reps': reps,
        'weight': weight,
      });

      final response = await _executeWithRetry(() => _post(url.toString(), body: body));

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final workoutSet = WorkoutSet.fromJson(data);
        
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
        
        return workoutSet;
      } else {
        throw Exception('Ошибка создания подхода: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createSet: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  /// Массовое создание подходов для упражнения
  Future<List<WorkoutSet>> createBulkSets({
    required String workoutExerciseId,
    required List<Map<String, dynamic>> sets,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/sets/bulk/$workoutExerciseId');
      
      final body = json.encode(sets);

      final response = await _executeWithRetry(() => _post(url.toString(), body: body));

      if (response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        final workoutSets = data.map((setJson) => WorkoutSet.fromJson(setJson)).toList();
        
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
        
        return workoutSets;
      } else {
        throw Exception('Ошибка создания подходов: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createBulkSets: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  /// Обновление подхода
  Future<WorkoutSet> updateSet({
    required String setId,
    required int reps,
    required double weight,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/sets/$setId');
      
      final body = json.encode({
        'reps': reps,
        'weight': weight,
      });

      final response = await _executeWithRetry(() => _put(url.toString(), body: body));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final workoutSet = WorkoutSet.fromJson(data);
        
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
        
        return workoutSet;
      } else {
        throw Exception('Ошибка обновления подхода: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateSet: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  /// Удаление подхода
  Future<void> deleteSet(String setId) async {
    try {
      final url = Uri.parse('$baseUrl/sets/$setId');
      
      final response = await _executeWithRetry(() => _delete(url.toString()));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Очищаем кэш для обновления данных
        _clearWorkoutRelatedCaches();
      } else {
        throw Exception('Ошибка удаления подхода: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteSet: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания ответа');
      } else {
        rethrow;
      }
    }
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  /// Форматирование даты в строку YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Очистка кэшей, связанных с тренировками
  void _clearWorkoutRelatedCaches() {
    _workoutsCache.clear();
    _statisticsCache.clear();
  }

  /// Очистка кэша для конкретной даты
  void clearCacheForDate(DateTime date) {
    final dateString = _formatDate(date);
    final cacheKey = '${userId}_$dateString';
    _workoutsCache.remove(cacheKey);
    _statisticsCache.clear(); // Статистика может измениться
  }

  /// Очистка всех кэшей
  void clearAllCaches() {
    _workoutsCache.clear();
    _exercisesCache.clear();
    _statisticsCache.clear();
  }

  /// Освобождение ресурсов экземпляра
  void dispose() {
    _debounceTimer?.cancel();
  }

  /// Очистка всех кэшей для принудительного обновления данных
  Future<void> clearCache() async {
    _workoutsCache.clear();
    _exercisesCache.clear();
    _statisticsCache.clear();
  }

  /// Глобальная очистка ресурсов
  static void globalDispose() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
    _httpClient.close();
    _instance = null;
  }
}

/// Класс для кэша с TTL (время жизни)
class _CacheEntry<T> {
  final T value;
  final DateTime expirationTime;

  _CacheEntry(this.value, this.expirationTime);

  bool isExpired(DateTime now) {
    return now.isAfter(expirationTime);
  }
}
