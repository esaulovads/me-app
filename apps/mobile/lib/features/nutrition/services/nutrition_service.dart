import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/meal_model.dart';

class NutritionService {
  final String userId;
  
  // В Android эмуляторе localhost это 10.0.2.2
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3002';
    }
    return 'http://localhost:3002';
  }

  // Кэш для данных питания
  static final Map<String, DailySummary> _summaryCache = {};
  static final Map<String, List<Meal>> _mealsCache = {};
  
  // Debounce для предотвращения множественных запросов
  Timer? _debounceTimer;
  
  // Таймаут для HTTP запросов
  static const Duration _requestTimeout = Duration(seconds: 10);

  NutritionService({required this.userId});

  // Получение всех приёмов пищи за конкретный день с кэшированием
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final dateString = _formatDate(date);
    final cacheKey = '${userId}_$dateString';
    
    // Проверяем кэш
    if (_mealsCache.containsKey(cacheKey)) {
      return _mealsCache[cacheKey]!;
    }

    try {
      final url = Uri.parse('$baseUrl/meals?date=$dateString');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'user-id': userId,
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final meals = data.map((mealJson) => Meal.fromJson(mealJson)).toList();
        
        // Кэшируем результат
        _mealsCache[cacheKey] = meals;
        return meals;
      } else if (response.statusCode == 404) {
        // 404 означает, что данных нет - это нормально, возвращаем пустой список
        final emptyMeals = <Meal>[];
        _mealsCache[cacheKey] = emptyMeals;
        return emptyMeals;
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      if (e.toString().contains('404')) {
        // 404 - нормальная ситуация, возвращаем пустой список
        final emptyMeals = <Meal>[];
        _mealsCache[cacheKey] = emptyMeals;
        return emptyMeals;
      }
      rethrow;
    }
  }

  // Получение дневной сводки КБЖУ за конкретный день с кэшированием и debounce
  Future<DailySummary> getDailySummary(DateTime date) async {
    final dateString = _formatDate(date);
    final cacheKey = '${userId}_$dateString';
    
    // Проверяем кэш
    if (_summaryCache.containsKey(cacheKey)) {
      return _summaryCache[cacheKey]!;
    }

    // Отменяем предыдущий запрос если он есть
    _debounceTimer?.cancel();
    
    final completer = Completer<DailySummary>();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final url = Uri.parse('$baseUrl/meals/summary?date=$dateString');
        
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'user-id': userId,
          },
        ).timeout(_requestTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final summary = DailySummary.fromJson(data);
          
          // Кэшируем результат
          _summaryCache[cacheKey] = summary;
          completer.complete(summary);
        } else if (response.statusCode == 404) {
          // 404 означает, что данных нет - возвращаем нулевую сводку
          final emptySummary = DailySummary(
            totalCalories: 0,
            totalProteins: 0,
            totalFats: 0,
            totalCarbs: 0,
          );
          _summaryCache[cacheKey] = emptySummary;
          completer.complete(emptySummary);
        } else {
          completer.completeError('Ошибка сервера: ${response.statusCode}');
        }
      } on SocketException {
        completer.completeError('Нет подключения к интернету');
      } on TimeoutException {
        completer.completeError('Превышено время ожидания ответа');
      } catch (e) {
        if (e.toString().contains('404')) {
          // 404 - нормальная ситуация, возвращаем пустую сводку
          final emptySummary = DailySummary(
            totalCalories: 0,
            totalProteins: 0,
            totalFats: 0,
            totalCarbs: 0,
          );
          _summaryCache[cacheKey] = emptySummary;
          completer.complete(emptySummary);
        } else {
          completer.completeError(e);
        }
      }
    });

    return completer.future;
  }

  // Получение дневной сводки КБЖУ за сегодня
  Future<DailySummary> getTodaySummary() async {
    return getDailySummary(DateTime.now());
  }

  // Создание нового приёма пищи
  Future<Meal> createMeal(DateTime dateTime) async {
    try {
      final url = Uri.parse('$baseUrl/meals');
      
      final body = json.encode({
        'time': dateTime.toIso8601String(),
        'items': [], // Пустой список блюд
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'user-id': userId,
        },
        body: body,
      ).timeout(_requestTimeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final meal = Meal.fromJson(data);
        
        // Очищаем кэш для этой даты, чтобы обновить данные
        clearCacheForDate(dateTime);
        
        return meal;
      } else {
        throw Exception('Ошибка создания приёма пищи: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      // Временное решение: создаем мок-данные для тестирования
      if (e.toString().contains('404') || e.toString().contains('Connection refused')) {
        final meal = _createMockMeal(dateTime);
        
        // Добавляем в кэш
        final dateKey = '${userId}_${_formatDate(dateTime)}';
        final existingMeals = _mealsCache[dateKey] ?? [];
        existingMeals.add(meal);
        _mealsCache[dateKey] = existingMeals;
        
        return meal;
      }
      rethrow;
    }
  }
  
  // Создание мок-данных для приёма пищи
  Meal _createMockMeal(DateTime dateTime) {
    final mealId = 'mock-meal-${DateTime.now().millisecondsSinceEpoch}';
    
    return Meal(
      id: mealId,
      userId: userId,
      name: 'Новый приём пищи',
      time: dateTime,
      totalCalories: 0,
      totalProteins: 0,
      totalFats: 0,
      totalCarbs: 0,
      items: [],
    );
  }

  // Очистка кэша (можно вызывать при добавлении новых данных)
  void clearCache() {
    _summaryCache.clear();
    _mealsCache.clear();
  }

  // Очистка кэша для конкретной даты
  void clearCacheForDate(DateTime date) {
    final dateString = _formatDate(date);
    final cacheKey = '${userId}_$dateString';
    _summaryCache.remove(cacheKey);
    _mealsCache.remove(cacheKey);
  }

  // Форматирование даты в строку YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Освобождение ресурсов
  void dispose() {
    _debounceTimer?.cancel();
  }
} 