import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthService {
  // В Android эмуляторе localhost это 10.0.2.2
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
  
  static const String _userIdKey = 'userId';
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Получение deviceId в зависимости от платформы
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      print('Error getting device ID: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Получение сохраненного userId
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Сохранение userId
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Аутентификация пользователя
  Future<String> authenticate() async {
    try {
      // Проверяем, есть ли сохраненный userId
      final savedUserId = await getSavedUserId();
      if (savedUserId != null && savedUserId.isNotEmpty) {
        print('Найден сохраненный userId: $savedUserId');
        
        // Проверяем, существует ли пользователь на сервере
        final userExists = await _checkUserExists(savedUserId);
        if (userExists) {
          print('Пользователь существует на сервере, используем сохраненный userId');
          return savedUserId;
        } else {
          print('Пользователь не найден на сервере, удаляем сохраненный userId');
          await _clearSavedUserId();
        }
      }

      print('Создаем нового пользователя...');
      // Если нет сохраненного userId или пользователь не существует,
      // создаем новую учетную запись
      final deviceId = await _getDeviceId();
      print('Device ID: $deviceId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['userId'] as String;
        print('Новый userId создан: $userId');
        await saveUserId(userId);
        return userId;
      } else {
        print('Ошибка создания пользователя: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to authenticate: ${response.body}');
      }
    } catch (e) {
      print('Error during authentication: $e');
      rethrow;
    }
  }

  // Очистка сохраненного userId
  Future<void> _clearSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  // Проверка существования пользователя
  Future<bool> _checkUserExists(String userId) async {
    try {
      print('Проверяем существование пользователя: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
      ).timeout(const Duration(seconds: 5));
      
      print('Ответ сервера: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка при проверке пользователя: $e');
      return false;
    }
  }
} 