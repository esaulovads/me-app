import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'auth_service.dart';

/// Сервис для отладки и управления авторизацией
class AuthDebugService {
  static const String _userIdKey = 'userId';
  
  /// Получает информацию о текущем состоянии авторизации
  static Future<Map<String, dynamic>> getAuthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString(_userIdKey);
    
    final authService = AuthService();
    
    return {
      'savedUserId': savedUserId,
      'hasSavedUser': savedUserId != null && savedUserId.isNotEmpty,
      'deviceId': await authService._getDeviceId(),
    };
  }
  
  /// Полностью очищает данные авторизации
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    print('Данные авторизации очищены');
  }
  
  /// Принудительно создает нового пользователя
  static Future<String> forceCreateNewUser() async {
    await clearAuthData();
    final authService = AuthService();
    final newUserId = await authService.authenticate();
    print('Создан новый пользователь: $newUserId');
    return newUserId;
  }
  
  /// Выводит отладочную информацию
  static Future<void> printDebugInfo() async {
    final info = await getAuthInfo();
    print('=== AUTH DEBUG INFO ===');
    print('Saved User ID: ${info['savedUserId']}');
    print('Has Saved User: ${info['hasSavedUser']}');
    print('Device ID: ${info['deviceId']}');
    print('=====================');
  }
}

// Расширение для AuthService чтобы получить доступ к приватному методу
extension AuthServiceDebug on AuthService {
  Future<String> _getDeviceId() async {
    // Копируем логику из приватного метода
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}
