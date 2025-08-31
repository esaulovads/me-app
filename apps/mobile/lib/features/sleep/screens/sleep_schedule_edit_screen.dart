import 'package:flutter/material.dart';
import '../models/sleep_schedule_model.dart';
import '../widgets/sleep_schedule_settings.dart';
import '../widgets/sleep_tracking_widget.dart';

/// Экран для редактирования расписания сна
class SleepScheduleEditScreen extends StatefulWidget {
  final String userId;
  final SleepSchedule? currentSchedule;

  const SleepScheduleEditScreen({
    Key? key,
    required this.userId,
    this.currentSchedule,
  }) : super(key: key);

  @override
  State<SleepScheduleEditScreen> createState() => _SleepScheduleEditScreenState();
}

class _SleepScheduleEditScreenState extends State<SleepScheduleEditScreen> {
  bool _hasChanges = false;
  SleepSchedule? _currentSchedule;

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.currentSchedule;
  }

  /// Обработчик обновления расписания
  void _onScheduleUpdated() {
    setState(() {
      _hasChanges = true;
    });
    
    // Возвращаемся назад с результатом
    Navigator.of(context).pop(true);
  }

  /// Обработчик для обновления локального состояния расписания
  void _onScheduleChanged(SleepSchedule? newSchedule) {
    setState(() {
      _currentSchedule = newSchedule;
      _hasChanges = true;
    });
  }

  /// Обработчик кнопки "Назад" с проверкой изменений
  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      // Если есть изменения, просто возвращаемся
      return true;
    }

    // Показываем диалог подтверждения только если пользователь что-то менял
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить изменения?'),
        content: const Text('Все несохраненные изменения будут потеряны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Продолжить редактирование'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Отменить изменения'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Настройка расписания'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Информационный блок
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Настройка расписания сна',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Регулярное расписание сна улучшает качество отдыха и общее самочувствие.',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Виджет настроек расписания
              SleepScheduleSettings(
                userId: widget.userId,
                currentSchedule: widget.currentSchedule,
                onScheduleUpdated: _onScheduleUpdated,
                onScheduleChanged: _onScheduleChanged,
              ),
              
              // Виджет отслеживания сна
              SleepTrackingWidget(
                userId: widget.userId,
                schedule: _currentSchedule,
                onScheduleNeeded: () {
                  // Если нужно настроить расписание, остаемся на этом экране
                  // Пользователь уже на экране настройки
                },
              ),
              
              // Дополнительный отступ снизу для удобства прокрутки
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}