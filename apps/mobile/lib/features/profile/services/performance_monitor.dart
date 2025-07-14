import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// Сервис для мониторинга производительности
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Счетчики производительности
  int _frameDrops = 0;
  int _totalFrames = 0;
  double _averageFrameTime = 0.0;
  final List<double> _frameTimes = [];
  
  // Флаг инициализации
  bool _isInitialized = false;
  
  // Максимальное количество сохраняемых времен кадров
  static const int _maxFrameTimesCount = 100;
  
  // Пороговое значение для определения пропущенного кадра (16.67ms для 60fps)
  static const double _frameDropThreshold = 16.67;

  // Инициализация мониторинга
  void initialize() {
    if (_isInitialized) return;
    
    // Включаем мониторинг только в debug режиме
    if (kDebugMode) {
      try {
        // Просто пытаемся получить доступ к SchedulerBinding
        // Если Flutter binding инициализирован, это должно работать
        SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
        _isInitialized = true;
        _log('Performance monitoring initialized');
      } catch (e) {
        _log('Error initializing performance monitoring: $e');
        // Не блокируем работу приложения, просто отключаем мониторинг
      }
    }
  }

  // Обработка времени кадров
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // в миллисекундах
      
      _totalFrames++;
      _frameTimes.add(frameTime);
      
      // Ограничиваем размер списка
      if (_frameTimes.length > _maxFrameTimesCount) {
        _frameTimes.removeAt(0);
      }
      
      // Проверяем на пропущенный кадр
      if (frameTime > _frameDropThreshold) {
        _frameDrops++;
        _logFrameDrop(frameTime);
      }
      
      // Обновляем среднее время кадра
      _averageFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    }
  }

  // Логирование пропущенного кадра
  void _logFrameDrop(double frameTime) {
    _log('Frame drop detected: ${frameTime.toStringAsFixed(2)}ms');
  }

  // Получение статистики производительности
  PerformanceStats getStats() {
    return PerformanceStats(
      totalFrames: _totalFrames,
      frameDrops: _frameDrops,
      frameDropRate: _totalFrames > 0 ? (_frameDrops / _totalFrames) * 100 : 0.0,
      averageFrameTime: _averageFrameTime,
      currentFps: _averageFrameTime > 0 ? 1000 / _averageFrameTime : 0.0,
    );
  }

  // Сброс статистики
  void resetStats() {
    _frameDrops = 0;
    _totalFrames = 0;
    _averageFrameTime = 0.0;
    _frameTimes.clear();
    _log('Performance stats reset');
  }

  // Логирование времени выполнения операции
  T measureOperation<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      final duration = stopwatch.elapsedMilliseconds;
      _log('Operation "$operationName" took ${duration}ms');
      
      // Предупреждение о медленных операциях
      if (duration > 100) {
        _log('WARNING: Slow operation detected - "$operationName" took ${duration}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _log('ERROR: Operation "$operationName" failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // Асинхронное измерение времени выполнения
  Future<T> measureAsyncOperation<T>(String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final duration = stopwatch.elapsedMilliseconds;
      _log('Async operation "$operationName" took ${duration}ms');
      
      // Предупреждение о медленных операциях
      if (duration > 500) {
        _log('WARNING: Slow async operation detected - "$operationName" took ${duration}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _log('ERROR: Async operation "$operationName" failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // Мониторинг использования памяти
  void logMemoryUsage(String context) {
    if (kDebugMode) {
      try {
        // Получаем информацию о памяти процесса
        final info = ProcessInfo.currentRss;
        final memoryMB = info / (1024 * 1024); // Конвертируем в MB
        _log('Memory usage in $context: ${memoryMB.toStringAsFixed(2)} MB');
      } catch (e) {
        _log('Memory monitoring unavailable in $context: $e');
      }
    }
  }

  // Создание отчета о производительности
  String generatePerformanceReport() {
    final stats = getStats();
    
    return '''
=== Performance Report ===
Total Frames: ${stats.totalFrames}
Frame Drops: ${stats.frameDrops}
Frame Drop Rate: ${stats.frameDropRate.toStringAsFixed(2)}%
Average Frame Time: ${stats.averageFrameTime.toStringAsFixed(2)}ms
Current FPS: ${stats.currentFps.toStringAsFixed(1)}
Frame Times (last ${_frameTimes.length}): ${_frameTimes.map((t) => t.toStringAsFixed(1)).join(', ')}
=========================
''';
  }

  // Логирование с временной меткой
  void _log(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      developer.log('[$timestamp] [PERF] $message');
    }
  }

  // Очистка ресурсов
  void dispose() {
    if (_isInitialized) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      _isInitialized = false;
      _log('Performance monitoring disposed');
    }
  }
}

// Класс для хранения статистики производительности
class PerformanceStats {
  final int totalFrames;
  final int frameDrops;
  final double frameDropRate;
  final double averageFrameTime;
  final double currentFps;

  const PerformanceStats({
    required this.totalFrames,
    required this.frameDrops,
    required this.frameDropRate,
    required this.averageFrameTime,
    required this.currentFps,
  });

  @override
  String toString() {
    return 'PerformanceStats(totalFrames: $totalFrames, frameDrops: $frameDrops, '
           'frameDropRate: ${frameDropRate.toStringAsFixed(2)}%, '
           'averageFrameTime: ${averageFrameTime.toStringAsFixed(2)}ms, '
           'currentFps: ${currentFps.toStringAsFixed(1)})';
  }
}

// Миксин для удобного использования мониторинга в виджетах
mixin PerformanceMonitorMixin {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  // Измерение времени выполнения операции
  T measurePerformance<T>(String operationName, T Function() operation) {
    return _monitor.measureOperation(operationName, operation);
  }

  // Асинхронное измерение времени выполнения
  Future<T> measureAsyncPerformance<T>(String operationName, Future<T> Function() operation) {
    return _monitor.measureAsyncOperation(operationName, operation);
  }

  // Логирование использования памяти
  void logMemoryUsage(String context) {
    _monitor.logMemoryUsage(context);
  }

  // Получение статистики
  PerformanceStats getPerformanceStats() {
    return _monitor.getStats();
  }
} 