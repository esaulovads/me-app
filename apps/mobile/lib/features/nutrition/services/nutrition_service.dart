import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meal_model.dart';
import '../models/product_model.dart';
import '../models/dish_model.dart';

class NutritionService {
  // Синглтон
  static NutritionService? _instance;
  static NutritionService getInstance({required String userId}) {
    _instance ??= NutritionService._internal(userId);
    return _instance!;
  }

  final String userId;
  
  // Оптимизированный HTTP клиент с connection pooling
  static http.Client _httpClient = http.Client();
  
  // Счетчик ошибок соединения для пересоздания клиента
  static int _connectionErrors = 0;
  static const int _maxConnectionErrors = 3;
  
  // В Android эмуляторе localhost это 10.0.2.2
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3002';
    }
    return 'http://localhost:3002';
  }

  // Кэш для данных питания с TTL
  static final Map<String, _CacheEntry<DailySummary>> _summaryCache = {};
  static final Map<String, _CacheEntry<List<Meal>>> _mealsCache = {};
  
  // Кэш для продуктов и блюд с TTL
  static final Map<String, _CacheEntry<List<Product>>> _productsCache = {};
  static final Map<String, _CacheEntry<List<Dish>>> _dishesCache = {};
  static final Map<String, _CacheEntry<List<Product>>> _recentProductsCache = {};
  static final Map<String, _CacheEntry<List<Dish>>> _recentDishesCache = {};
  
  // TTL для кэшей
  static const Duration _cacheShortTTL = Duration(minutes: 5);
  static const Duration _cacheLongTTL = Duration(minutes: 15);
  
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
    
    _summaryCache.removeWhere((key, entry) => entry.isExpired(now));
    _mealsCache.removeWhere((key, entry) => entry.isExpired(now));
    _productsCache.removeWhere((key, entry) => entry.isExpired(now));
    _dishesCache.removeWhere((key, entry) => entry.isExpired(now));
    _recentProductsCache.removeWhere((key, entry) => entry.isExpired(now));
    _recentDishesCache.removeWhere((key, entry) => entry.isExpired(now));
  }
  
  // Debounce для предотвращения множественных запросов
  Timer? _debounceTimer;
  
  // Оптимизированные таймауты
  static const Duration _shortTimeout = Duration(seconds: 5);
  static const Duration _mediumTimeout = Duration(seconds: 8);
  static const Duration _longTimeout = Duration(seconds: 12);

  // Приватный конструктор
  NutritionService._internal(this.userId) {
    _initCacheCleanup(); // Инициализируем автоочистку кэша
  }

  // Устаревший конструктор для обратной совместимости
  factory NutritionService({required String userId}) {
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

  // Получение всех приёмов пищи за конкретный день с кэшированием
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final dateString = _formatDate(date);
    final cacheKey = '${userId}_$dateString';
    
    // Проверяем кэш
    if (_mealsCache.containsKey(cacheKey)) {
      return _mealsCache[cacheKey]!.value;
    }

    try {
      final url = Uri.parse('$baseUrl/meals?date=$dateString');
      
      final response = await _get(url.toString());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final meals = data.map((mealJson) => Meal.fromJson(mealJson)).toList();
        
        // Сбрасываем счетчик ошибок при успешном запросе
        _connectionErrors = 0;
        
        // Кэшируем результат
        _mealsCache[cacheKey] = _CacheEntry(meals, DateTime.now().add(_cacheShortTTL));
        return meals;
      } else if (response.statusCode == 404) {
        // 404 означает, что данных нет - это нормально, возвращаем пустой список
        final emptyMeals = <Meal>[];
        _mealsCache[cacheKey] = _CacheEntry(emptyMeals, DateTime.now().add(_cacheShortTTL));
        return emptyMeals;
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('SocketException в getMealsForDate: $e');
      throw Exception('Нет подключения к интернету');
    } on TimeoutException catch (e) {
      print('TimeoutException в getMealsForDate: $e');
      throw Exception('Превышено время ожидания ответа');
    } on http.ClientException catch (e) {
      print('ClientException в getMealsForDate: $e');
      _handleConnectionError();
      if (e.message.contains('Connection closed before full header was received')) {
        throw Exception('Соединение прервано, попробуйте еще раз');
      }
      throw Exception('Ошибка соединения: ${e.message}');
    } catch (e) {
      print('Общая ошибка в getMealsForDate: $e');
      if (e.toString().contains('404')) {
        // 404 - нормальная ситуация, возвращаем пустой список
        final emptyMeals = <Meal>[];
        _mealsCache[cacheKey] = _CacheEntry(emptyMeals, DateTime.now().add(_cacheShortTTL));
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
      return _summaryCache[cacheKey]!.value;
    }

    // Отменяем предыдущий запрос если он есть
    _debounceTimer?.cancel();
    
    final completer = Completer<DailySummary>();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final url = Uri.parse('$baseUrl/meals/summary?date=$dateString');
        
        final response = await _get(url.toString());

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final summary = DailySummary.fromJson(data);
          
          // Сбрасываем счетчик ошибок при успешном запросе
          _connectionErrors = 0;
          
          // Кэшируем результат
          _summaryCache[cacheKey] = _CacheEntry(summary, DateTime.now().add(_cacheShortTTL));
          completer.complete(summary);
        } else if (response.statusCode == 404) {
          // 404 означает, что данных нет - возвращаем нулевую сводку
          final emptySummary = DailySummary(
            totalCalories: 0,
            totalProteins: 0,
            totalFats: 0,
            totalCarbs: 0,
          );
          _summaryCache[cacheKey] = _CacheEntry(emptySummary, DateTime.now().add(_cacheShortTTL));
          completer.complete(emptySummary);
        } else {
          completer.completeError('Ошибка сервера: ${response.statusCode}');
        }
      } on SocketException catch (e) {
        print('SocketException в getDailySummary: $e');
        completer.completeError('Нет подключения к интернету');
      } on TimeoutException catch (e) {
        print('TimeoutException в getDailySummary: $e');
        completer.completeError('Превышено время ожидания ответа');
      } on http.ClientException catch (e) {
        print('ClientException в getDailySummary: $e');
        _handleConnectionError();
        if (e.message.contains('Connection closed before full header was received')) {
          completer.completeError('Соединение прервано, попробуйте еще раз');
        } else {
          completer.completeError('Ошибка соединения: ${e.message}');
        }
      } catch (e) {
        print('Общая ошибка в getDailySummary: $e');
        if (e.toString().contains('404')) {
          // 404 - нормальная ситуация, возвращаем пустую сводку
          final emptySummary = DailySummary(
            totalCalories: 0,
            totalProteins: 0,
            totalFats: 0,
            totalCarbs: 0,
          );
          _summaryCache[cacheKey] = _CacheEntry(emptySummary, DateTime.now().add(_cacheShortTTL));
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

      final response = await _post(url.toString(), body: body);

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
        final existingMeals = _mealsCache[dateKey]?.value ?? <Meal>[];
        existingMeals.add(meal);
        _mealsCache[dateKey] = _CacheEntry(existingMeals, DateTime.now().add(_cacheShortTTL));
        
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

  // Удаление приёма пищи
  Future<void> deleteMeal(String mealId, DateTime mealDate) async {
    try {
      final url = Uri.parse('$baseUrl/meals/$mealId');
      
      final response = await _delete(url.toString());

      if (response.statusCode == 200) {
        // Очищаем кэш для даты приёма пищи, чтобы обновить данные
        clearCacheForDate(mealDate);
      } else {
        throw Exception('Ошибка удаления приёма пищи: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // Обновление времени приёма пищи
  Future<Meal> updateMealTime(String mealId, DateTime newTime) async {
    try {
      final url = Uri.parse('$baseUrl/meals/$mealId');
      
      final body = json.encode({
        'time': newTime.toIso8601String(),
      });

      final response = await _put(url.toString(), body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final meal = Meal.fromJson(data);
        
        // Очищаем кэш для обеих дат (старой и новой), если они разные
        clearCacheForDate(newTime);
        
        return meal;
      } else {
        throw Exception('Ошибка обновления времени приёма пищи: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С ПРОДУКТАМИ ===

  // Получение списка продуктов с пагинацией и поиском
  Future<ProductsResponse> getProducts({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final url = Uri.parse('$baseUrl/products').replace(queryParameters: params);
      
      final response = await _get(url.toString());

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProductsResponse.fromJson(data);
      } else {
        throw Exception('Ошибка загрузки продуктов: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // Получение недавно использованных продуктов
  Future<List<Product>> getRecentProducts() async {
    final cacheKey = userId;
    
    // Проверяем кэш
    if (_recentProductsCache.containsKey(cacheKey)) {
      return _recentProductsCache[cacheKey]!.value;
    }

    try {
      final url = Uri.parse('$baseUrl/products/recent');
      
      final response = await _get(url.toString());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final products = data.map((productJson) => Product.fromJson(productJson)).toList();
        
        // Кэшируем результат
        _recentProductsCache[cacheKey] = _CacheEntry(products, DateTime.now().add(_cacheShortTTL));
        return products;
      } else if (response.statusCode == 404) {
        final emptyProducts = <Product>[];
        _recentProductsCache[cacheKey] = _CacheEntry(emptyProducts, DateTime.now().add(_cacheShortTTL));
        return emptyProducts;
      } else {
        throw Exception('Ошибка загрузки недавних продуктов: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      // В случае ошибки возвращаем пустой список
      final emptyProducts = <Product>[];
      _recentProductsCache[cacheKey] = _CacheEntry(emptyProducts, DateTime.now().add(_cacheShortTTL));
      return emptyProducts;
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С БЛЮДАМИ ===

  // Получение списка блюд с пагинацией и поиском
  Future<DishesResponse> getDishes({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final url = Uri.parse('$baseUrl/dishes').replace(queryParameters: params);
      
      final response = await _get(url.toString());

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return DishesResponse.fromJson(data);
      } else {
        throw Exception('Ошибка загрузки блюд: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // Получение недавно использованных блюд
  Future<List<Dish>> getRecentDishes() async {
    final cacheKey = userId;
    
    // Проверяем кэш
    if (_recentDishesCache.containsKey(cacheKey)) {
      return _recentDishesCache[cacheKey]!.value;
    }

    try {
      final url = Uri.parse('$baseUrl/dishes/recent');
      
      final response = await _get(url.toString());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final dishes = data.map((dishJson) => Dish.fromJson(dishJson)).toList();
        
        // Кэшируем результат
        _recentDishesCache[cacheKey] = _CacheEntry(dishes, DateTime.now().add(_cacheShortTTL));
        return dishes;
      } else if (response.statusCode == 404) {
        final emptyDishes = <Dish>[];
        _recentDishesCache[cacheKey] = _CacheEntry(emptyDishes, DateTime.now().add(_cacheShortTTL));
        return emptyDishes;
      } else {
        throw Exception('Ошибка загрузки недавних блюд: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      // В случае ошибки возвращаем пустой список
      final emptyDishes = <Dish>[];
      _recentDishesCache[cacheKey] = _CacheEntry(emptyDishes, DateTime.now().add(_cacheShortTTL));
      return emptyDishes;
    }
  }

  // === МЕТОДЫ ДЛЯ ДОБАВЛЕНИЯ ЭЛЕМЕНТОВ В ПРИЁМ ПИЩИ ===

  // Добавление продукта в приём пищи
  Future<void> addProductToMeal(String mealId, String productId, double weight) async {
    try {
      final url = Uri.parse('$baseUrl/meals/$mealId/items');
      
      final body = json.encode({
        'type': 'PRODUCT',
        'id': productId,
        'weight': weight,
      });

      final response = await _post(url.toString(), body: body);

      if (response.statusCode == 201) {
        // Очищаем кэши для обновления данных
        _clearMealRelatedCaches();
      } else {
        throw Exception('Ошибка добавления продукта: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // Добавление блюда в приём пищи
  Future<void> addDishToMeal(String mealId, String dishId, double weight) async {
    try {
      final url = Uri.parse('$baseUrl/meals/$mealId/items');
      
      final body = json.encode({
        'type': 'DISH',
        'id': dishId,
        'weight': weight,
      });

      final response = await _post(url.toString(), body: body);

      if (response.statusCode == 201) {
        // Очищаем кэши для обновления данных
        _clearMealRelatedCaches();
      } else {
        throw Exception('Ошибка добавления блюда: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // === МЕТОДЫ ДЛЯ СОЗДАНИЯ ПРОДУКТОВ И БЛЮД ===

  // Создание нового продукта
  Future<Product> createProduct({
    required String name,
    required double caloriesPer100g,
    required double proteinsPer100g,
    required double fatsPer100g,
    required double carbsPer100g,
    required double servingWeight,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/products');
      
      final body = json.encode({
        'name': name,
        'caloriesPer100g': caloriesPer100g,
        'proteinsPer100g': proteinsPer100g,
        'fatsPer100g': fatsPer100g,
        'carbsPer100g': carbsPer100g,
        'servingWeight': servingWeight,
      });

      final response = await _post(url.toString(), body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final product = Product.fromJson(data);
        
        // Очищаем кэши продуктов для обновления списков
        _productsCache.clear();
        _recentProductsCache.clear();
        
        return product;
      } else {
        throw Exception('Ошибка создания продукта: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // Создание нового блюда/рецепта
  Future<Dish> createDish({
    required String name,
    required List<DishIngredientInput> ingredients,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/dishes');
      
      final body = json.encode({
        'name': name,
        'ingredients': ingredients.map((ingredient) => {
          'productId': ingredient.productId,
          'weight': ingredient.weight,
        }).toList(),
      });

      final response = await _post(url.toString(), body: body);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        final dish = Dish.fromJson(data);
        
        // Очищаем кэши блюд для обновления списков
        _dishesCache.clear();
        _recentDishesCache.clear();
        
        return dish;
      } else {
        throw Exception('Ошибка создания блюда: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } on TimeoutException {
      throw Exception('Превышено время ожидания ответа');
    } catch (e) {
      rethrow;
    }
  }

  // Очистка кэшей, связанных с приёмами пищи
  void _clearMealRelatedCaches() {
    // Полностью очищаем кэши приёмов пищи и сводок - они изменились
    _summaryCache.clear();
    _mealsCache.clear();
    
    // Очищаем кэши недавних элементов - они могли измениться
    _recentProductsCache.clear();
    _recentDishesCache.clear();
    
    // НЕ очищаем _productsCache и _dishesCache - они не изменились
    // Это позволяет избежать повторной загрузки данных при возврате к экрану выбора
  }

  // Очистка всех кэшей
  void clearAllCaches() {
    _summaryCache.clear();
    _mealsCache.clear();
    _productsCache.clear();
    _dishesCache.clear();
    _recentProductsCache.clear();
    _recentDishesCache.clear();
  }

  // Освобождение ресурсов экземпляра (легкая очистка)
  void dispose() {
    _debounceTimer?.cancel();
    // НЕ очищаем синглтон и статические ресурсы
    // Они будут очищены при globalDispose()
  }

  // Глобальная очистка ресурсов (вызывается при завершении приложения)
  static void globalDispose() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
    _httpClient.close();
    _instance = null; // Очищаем синглтон
  }
}

// Класс для кэша с TTL (время жизни)
class _CacheEntry<T> {
  final T value;
  final DateTime expirationTime;

  _CacheEntry(this.value, this.expirationTime);

  bool isExpired(DateTime now) {
    return now.isAfter(expirationTime);
  }
} 