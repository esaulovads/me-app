import 'package:flutter/material.dart';
import 'models/sleep_schedule_model.dart';
import 'services/sleep_service.dart';
import 'widgets/sleep_schedule_settings.dart';

/// Экран управления сном
class SleepScreen extends StatefulWidget {
  final String userId;

  const SleepScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  late SleepService _sleepService;
  SleepSchedule? _currentSchedule;
  bool _isLoading = true;
  String? _errorMessage;
  bool _serviceAvailable = true;

  @override
  void initState() {
    super.initState();
    _sleepService = SleepService(userId: widget.userId);
    _loadCurrentSchedule();
  }

  /// Загружает текущее расписание сна с быстрой проверкой доступности сервиса
  Future<void> _loadCurrentSchedule() async {
    try {
      // Сначала быстро проверяем доступность сервиса
      print('Проверяем доступность сервиса расписания сна...');
      final serviceAvailable = await _sleepService.isScheduleServiceAvailable();
      
      if (!mounted) return;
      
      if (!serviceAvailable) {
        print('Сервис расписания сна недоступен, переходим в fallback режим');
        setState(() {
          _isLoading = false;
          _serviceAvailable = false;
          _currentSchedule = null;
          _errorMessage = null; // Не показываем ошибку, просто работаем без расписания
        });
        return;
      }

      // Если сервис доступен, пытаемся загрузить расписание
      print('Загружаем расписание сна...');
      final schedule = await _sleepService.getSleepSchedule();
      
      if (!mounted) return;
      
      setState(() {
        _currentSchedule = schedule;
        _isLoading = false;
        _errorMessage = null;
        _serviceAvailable = true;
      });
      
      print('Расписание сна загружено: ${schedule != null ? 'найдено' : 'не настроено'}');
      
    } catch (e) {
      print('Ошибка загрузки расписания сна: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _serviceAvailable = false;
        _currentSchedule = null;
        _errorMessage = null; // Graceful fallback без показа ошибки
      });
    }
  }

  /// Обработчик обновления расписания
  void _onScheduleUpdated() {
    _loadCurrentSchedule();
  }

  /// Повторная попытка загрузки
  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadCurrentSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сон'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка расписания сна...'),
              ],
            ),
          )
        : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        // Продолжить без загрузки расписания
                        setState(() {
                          _errorMessage = null;
                          _currentSchedule = null;
                          _serviceAvailable = false;
                        });
                      },
                      child: const Text('Продолжить без расписания'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Показываем уведомление если сервис недоступен
                  if (!_serviceAvailable)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Расписание сна временно недоступно',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Функция настройки расписания будет доступна после обновления сервиса.',
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _retry,
                            child: const Text('Обновить'),
                          ),
                        ],
                      ),
                    ),
                  
                  // Блок настройки расписания сна (только если сервис доступен)
                  if (_serviceAvailable)
                    SleepScheduleSettings(
                      userId: widget.userId,
                      currentSchedule: _currentSchedule,
                      onScheduleUpdated: _onScheduleUpdated,
                    ),
                  
                  // Заглушка для будущего функционала
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bedtime, color: Colors.indigo),
                              const SizedBox(width: 8),
                              const Text(
                                'Записи сна',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Здесь будет возможность просматривать\nи управлять записями о сне',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _sleepService.dispose();
    super.dispose();
  }
} 