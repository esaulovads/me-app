import 'package:flutter/material.dart';
import '../models/sleep_session_model.dart';

/// Модалка для добавления/редактирования периода сна
class AddSleepPeriodModal extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime sleepTime, DateTime wakeTime, [String? sessionId]) onSave;
  final SleepSession? existingSession; // Для редактирования

  const AddSleepPeriodModal({
    Key? key,
    required this.selectedDate,
    required this.onSave,
    this.existingSession,
  }) : super(key: key);

  @override
  State<AddSleepPeriodModal> createState() => _AddSleepPeriodModalState();
}

class _AddSleepPeriodModalState extends State<AddSleepPeriodModal> {
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Если редактируем существующую сессию, используем её данные
    if (widget.existingSession != null) {
      _sleepTime = TimeOfDay.fromDateTime(widget.existingSession!.sleepTime);
      _wakeTime = TimeOfDay.fromDateTime(widget.existingSession!.wakeTime);
    } else {
      // Устанавливаем время по умолчанию для нового периода
      _sleepTime = const TimeOfDay(hour: 23, minute: 0); // 23:00
      _wakeTime = const TimeOfDay(hour: 7, minute: 0);   // 07:00
    }
  }

  /// Форматирует TimeOfDay в строку HH:mm
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Выбор времени засыпания
  Future<void> _selectSleepTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime ?? const TimeOfDay(hour: 23, minute: 0),
      helpText: 'Время засыпания',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (picked != null) {
      setState(() {
        _sleepTime = picked;
      });
    }
  }

  /// Выбор времени пробуждения
  Future<void> _selectWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime ?? const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Время пробуждения',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (picked != null) {
      setState(() {
        _wakeTime = picked;
      });
    }
  }

  /// Вычисляет продолжительность сна
  Duration _calculateSleepDuration() {
    if (_sleepTime == null || _wakeTime == null) {
      return Duration.zero;
    }

    // Создаем DateTime объекты для расчета
    final sleepDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _sleepTime!.hour,
      _sleepTime!.minute,
    );

    DateTime wakeDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _wakeTime!.hour,
      _wakeTime!.minute,
    );

    // Если время пробуждения раньше времени засыпания, значит сон переходит на следующий день
    if (wakeDateTime.isBefore(sleepDateTime)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }

    return wakeDateTime.difference(sleepDateTime);
  }

  /// Форматирует продолжительность в читаемый вид
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours} ч ${minutes} мин';
    } else {
      return '${minutes} мин';
    }
  }

  /// Проверяет валидность данных
  bool _isValid() {
    return _sleepTime != null && _wakeTime != null && !_isLoading;
  }

  /// Сохранение периода сна
  Future<void> _save() async {
    if (!_isValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Создаем полные DateTime объекты
      final sleepDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _sleepTime!.hour,
        _sleepTime!.minute,
      );

      DateTime wakeDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _wakeTime!.hour,
        _wakeTime!.minute,
      );

      // Если время пробуждения раньше времени засыпания, добавляем день
      if (wakeDateTime.isBefore(sleepDateTime)) {
        wakeDateTime = wakeDateTime.add(const Duration(days: 1));
      }

      // Вызываем колбэк для сохранения, передаем ID сессии если редактируем
      await widget.onSave(sleepDateTime, wakeDateTime, widget.existingSession?.id);

      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true как признак успешного сохранения
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepDuration = _calculateSleepDuration();
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9, // Ограничиваем высоту
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView( // Добавляем прокрутку
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Заголовок
              Row(
                children: [
                  const Icon(Icons.bedtime, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.existingSession != null 
                          ? 'Редактировать период сна' 
                          : 'Добавить период сна',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Информация о выбранной дате
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Дата: ${widget.selectedDate.day}.${widget.selectedDate.month.toString().padLeft(2, '0')}.${widget.selectedDate.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Время засыпания
              Row(
                children: [
                  const Icon(Icons.nightlight_round, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Время засыпания',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _selectSleepTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _sleepTime != null
                                  ? _formatTime(_sleepTime!)
                                  : 'Выберите время',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Время пробуждения
              Row(
                children: [
                  const Icon(Icons.wb_sunny, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Время пробуждения',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _selectWakeTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _wakeTime != null
                                  ? _formatTime(_wakeTime!)
                                  : 'Выберите время',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Продолжительность сна
              if (sleepDuration.inMinutes > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Продолжительность: ${_formatDuration(sleepDuration)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid() ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
