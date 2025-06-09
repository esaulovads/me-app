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

  ProfileService({required this.userId});

  // Получение профиля
  Future<Profile> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles'),
        headers: {'user-id': userId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Profile(
          name: data['name'],
          birthDate: data['birthDate'] != null ? DateTime.parse(data['birthDate']) : null,
          gender: data['gender'] != null ? Gender.values.firstWhere(
            (e) => e.toString().split('.').last == data['gender'],
            orElse: () => Gender.notSpecified,
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
        );
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }

  // Проверка заполненности профиля
  Future<bool> isProfileComplete() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/complete'),
        headers: {'user-id': userId},
      );

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
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      // TODO: Добавить нормальную обработку ошибок
      print('Error updating profile: $e');
      rethrow;
    }
  }
} 