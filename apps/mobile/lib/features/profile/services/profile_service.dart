import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/profile_model.dart';

class ProfileService {
  // В Android эмуляторе localhost это 10.0.2.2
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://localhost:3001';
  }

  final String userId;
  
  // Кэш для профиля пользователя
  static Profile? _cachedProfile;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  ProfileService({required this.userId});

  // Получение профиля с кэшированием
  Future<Profile> getProfile() async {
    // Проверяем кэш
    if (_cachedProfile != null && 
        _cacheTimestamp != null && 
        DateTime.now().difference(_cacheTimestamp!) < _cacheExpiration) {
      return _cachedProfile!;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles'),
        headers: {'user-id': userId},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = Profile(
          name: data['name'],
          birthDate: data['birthDate'] != null ? DateTime.parse(data['birthDate']) : null,
          gender: data['gender'] != null ? Gender.values.firstWhere(
            (e) => e.toString().split('.').last == data['gender'],
            orElse: () => Gender.male,
          ) : null,
          height: data['height']?.toDouble(),
          weight: data['weight']?.toDouble(),
          goal: data['goal'] != null ? UserGoal.values.firstWhere(
            (e) => e.toString().split('.').last == data['goal'],
            orElse: () => UserGoal.MAINTAIN_WEIGHT,
          ) : null,
          activityLevel: data['activityLevel'] != null ? ActivityLevel.values.firstWhere(
            (e) => e.toString().split('.').last == data['activityLevel'],
            orElse: () => ActivityLevel.MODERATELY_ACTIVE,
          ) : null,
          tdee: data['tdee']?.toDouble(),
          proteinTarget: data['proteinTarget']?.toDouble(),
          fatTarget: data['fatTarget']?.toDouble(),
          carbTarget: data['carbTarget']?.toDouble(),
        );
        
        // Кэшируем результат
        _cachedProfile = profile;
        _cacheTimestamp = DateTime.now();
        
        return profile;
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }

  // Проверка заполненности профиля с кэшированием
  Future<bool> isProfileComplete() async {
    try {
      // Сначала пытаемся получить из кэша
      if (_cachedProfile != null) {
        return _isProfileComplete(_cachedProfile!);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/complete'),
        headers: {'user-id': userId},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isComplete'] as bool;
      } else {
        throw Exception('Failed to check profile completion: ${response.body}');
      }
    } catch (e) {
      print('Error checking profile completion: $e');
      rethrow;
    }
  }

  // Локальная проверка заполненности профиля
  bool _isProfileComplete(Profile profile) {
    return profile.name != null && 
           profile.name!.isNotEmpty &&
           profile.gender != null &&
           profile.birthDate != null &&
           profile.height != null &&
           profile.weight != null &&
           profile.goal != null &&
           profile.activityLevel != null;
  }

  // Батчевое обновление профиля
  Future<void> updateProfileBatch(Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profiles/batch'),
        headers: {
          'Content-Type': 'application/json',
          'user-id': userId,
        },
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Сбрасываем кэш после успешного обновления
        _clearCache();
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile batch: $e');
      rethrow;
    }
  }

  // Обновление имени
  Future<void> updateName(String name) async {
    await _putRequest('/profiles/name', {'name': name});
  }

  // Обновление пола
  Future<void> updateGender(Gender gender) async {
    final genderString = gender.toString().split('.').last.toUpperCase();
    await _putRequest('/profiles/gender', {'gender': genderString});
  }

  // Обновление даты рождения
  Future<void> updateBirthDate(DateTime birthDate) async {
    await _putRequest('/profiles/birth-date', {
      'birthDate': birthDate.toIso8601String().split('T')[0],
    });
  }

  // Обновление роста
  Future<void> updateHeight(double height) async {
    await _putRequest('/profiles/height', {'height': height});
  }

  // Обновление веса
  Future<void> updateWeight(double weight) async {
    await _putRequest('/profiles/weight', {'weight': weight});
  }

  // Обновление цели
  Future<void> updateGoal(UserGoal goal) async {
    await _putRequest('/profiles/goal', {'goal': goal.name});
  }

  // Обновление уровня активности
  Future<void> updateActivityLevel(ActivityLevel level) async {
    await _putRequest('/profiles/activity-level', {'activityLevel': level.name});
  }

  // Общий метод для отправки PUT запроса
  Future<void> _putRequest(String path, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'user-id': userId,
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Сбрасываем кэш после успешного обновления
        _clearCache();
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Очистка кэша
  static void _clearCache() {
    _cachedProfile = null;
    _cacheTimestamp = null;
  }

  // Принудительная очистка кэша (для использования извне)
  void clearCache() {
    _clearCache();
  }
} 