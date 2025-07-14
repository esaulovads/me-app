import 'dart:isolate';
import 'dart:async';
import '../models/profile_model.dart';

// Сервис для оптимизации производительности
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Пул изолятов для тяжелых вычислений
  final List<Isolate> _isolates = [];
  final List<SendPort> _sendPorts = [];
  bool _isInitialized = false;

  // Инициализация пула изолятов
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Создаем 2 изолята для параллельных вычислений
      for (int i = 0; i < 2; i++) {
        final receivePort = ReceivePort();
        final isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);
        
        final sendPort = await receivePort.first as SendPort;
        
        _isolates.add(isolate);
        _sendPorts.add(sendPort);
      }
      
      _isInitialized = true;
      print('[PERF] Performance service initialized with ${_isolates.length} isolates');
    } catch (e) {
      print('[PERF] Warning: Failed to initialize isolates: $e');
      print('[PERF] Performance service will work without isolates');
      _isInitialized = true; // Помечаем как инициализированный, чтобы не блокировать работу
    }
  }

  // Точка входа для изолята
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        final type = message['type'] as String;
        final data = message['data'];
        final responsePort = message['responsePort'] as SendPort;

        try {
          switch (type) {
            case 'calculateAge':
              final result = _calculateAge(data);
              responsePort.send({'success': true, 'result': result});
              break;
            case 'calculateBMI':
              final result = _calculateBMI(data);
              responsePort.send({'success': true, 'result': result});
              break;
            case 'calculateTDEE':
              final result = _calculateTDEE(data);
              responsePort.send({'success': true, 'result': result});
              break;
            case 'processNutritionData':
              final result = _processNutritionData(data);
              responsePort.send({'success': true, 'result': result});
              break;
            default:
              responsePort.send({'success': false, 'error': 'Unknown operation'});
          }
        } catch (e) {
          responsePort.send({'success': false, 'error': e.toString()});
        }
      }
    });
  }

  // Расчет возраста в изоляте
  static String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 'Возраст не указан';
    
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return '$age лет';
  }

  // Расчет ИМТ в изоляте
  static double? _calculateBMI(Map<String, dynamic> data) {
    final height = data['height'] as double?;
    final weight = data['weight'] as double?;
    
    if (height == null || weight == null) return null;
    
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Расчет TDEE в изоляте
  static double? _calculateTDEE(Map<String, dynamic> data) {
    final height = data['height'] as double?;
    final weight = data['weight'] as double?;
    final age = data['age'] as int?;
    final gender = data['gender'] as String?;
    final activityLevel = data['activityLevel'] as String?;
    
    if (height == null || weight == null || age == null || gender == null) {
      return null;
    }
    
    // Расчет базового метаболизма (BMR) по формуле Миффлина-Сан Жеора
    double bmr;
    if (gender == 'MALE') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
    
    // Коэффициенты активности
    double activityMultiplier = 1.2; // По умолчанию - малоподвижный образ жизни
    
    switch (activityLevel) {
      case 'SEDENTARY':
        activityMultiplier = 1.2;
        break;
      case 'LIGHTLY_ACTIVE':
        activityMultiplier = 1.375;
        break;
      case 'MODERATELY_ACTIVE':
        activityMultiplier = 1.55;
        break;
      case 'VERY_ACTIVE':
        activityMultiplier = 1.725;
        break;
      case 'EXTREMELY_ACTIVE':
        activityMultiplier = 1.9;
        break;
    }
    
    return bmr * activityMultiplier;
  }

  // Обработка данных питания в изоляте
  static Map<String, dynamic> _processNutritionData(Map<String, dynamic> data) {
    final consumedCalories = data['consumedCalories'] as double;
    final targetCalories = data['targetCalories'] as double;
    
    final percentage = targetCalories > 0 
        ? (consumedCalories / targetCalories).clamp(0.0, 1.0) 
        : 0.0;
    
    String colorName;
    if (percentage >= 0.8) {
      colorName = 'green';
    } else if (percentage >= 0.4) {
      colorName = 'orange';
    } else {
      colorName = 'red';
    }
    
    return {
      'percentage': percentage,
      'colorName': colorName,
      'percentageInt': (percentage * 100).toInt(),
    };
  }

  // Публичные методы для вызова из UI
  Future<String> calculateAge(DateTime? birthDate) async {
    if (!_isInitialized) await initialize();
    return _executeInIsolate('calculateAge', birthDate);
  }

  Future<double?> calculateBMI(double? height, double? weight) async {
    if (!_isInitialized) await initialize();
    return _executeInIsolate('calculateBMI', {'height': height, 'weight': weight});
  }

  Future<double?> calculateTDEE({
    required double? height,
    required double? weight,
    required int? age,
    required String? gender,
    required String? activityLevel,
  }) async {
    if (!_isInitialized) await initialize();
    return _executeInIsolate('calculateTDEE', {
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
    });
  }

  Future<Map<String, dynamic>> processNutritionData(double consumedCalories, double targetCalories) async {
    if (!_isInitialized) await initialize();
    return _executeInIsolate('processNutritionData', {
      'consumedCalories': consumedCalories,
      'targetCalories': targetCalories,
    });
  }

  // Выполнение операции в изоляте с fallback
  Future<T> _executeInIsolate<T>(String operation, dynamic data) async {
    // Если изоляты не доступны, выполняем в основном потоке
    if (_sendPorts.isEmpty) {
      return _executeFallback<T>(operation, data);
    }
    
    try {
      final completer = Completer<T>();
      final responsePort = ReceivePort();
      
      // Выбираем свободный изолят (простая round-robin логика)
      final isolateIndex = DateTime.now().millisecondsSinceEpoch % _sendPorts.length;
      final sendPort = _sendPorts[isolateIndex];
      
      responsePort.listen((response) {
        responsePort.close();
        
        if (response is Map<String, dynamic>) {
          if (response['success'] == true) {
            completer.complete(response['result']);
          } else {
            completer.completeError(response['error'] ?? 'Unknown error');
          }
        } else {
          completer.completeError('Invalid response format');
        }
      });
      
      sendPort.send({
        'type': operation,
        'data': data,
        'responsePort': responsePort.sendPort,
      });
      
      return completer.future;
    } catch (e) {
      // Fallback на основной поток в случае ошибки
      print('[PERF] Error using isolate, falling back to main thread: $e');
      return _executeFallback<T>(operation, data);
    }
  }

  // Fallback методы для выполнения в основном потоке
  T _executeFallback<T>(String operation, dynamic data) {
    switch (operation) {
      case 'calculateAge':
        return _calculateAge(data) as T;
      case 'calculateBMI':
        return _calculateBMI(data) as T;
      case 'calculateTDEE':
        return _calculateTDEE(data) as T;
      case 'processNutritionData':
        return _processNutritionData(data) as T;
      default:
        throw Exception('Unknown operation: $operation');
    }
  }

  // Освобождение ресурсов
  void dispose() {
    for (final isolate in _isolates) {
      isolate.kill();
    }
    _isolates.clear();
    _sendPorts.clear();
    _isInitialized = false;
  }
} 