import 'package:flutter/material.dart';
import '../models/sleep_schedule_model.dart';
import '../services/sleep_service.dart';

/// Виджет для настройки расписания сна
class SleepScheduleSettings extends StatefulWidget {
  final String userId;
  final SleepSchedule? currentSchedule;
  final VoidCallback? onScheduleUpdated;

  const SleepScheduleSettings({
    Key? key,
    required this.userId,
    this.currentSchedule,
    this.onScheduleUpdated,
  }) : super(key: key);

  @override
  State<SleepScheduleSettings> createState() => _SleepScheduleSettingsState();
}

class _SleepScheduleSettingsState extends State<SleepScheduleSettings> {
  late SleepService _sleepService;
  ScheduleType _selectedType = ScheduleType.sameTime;
  bool _isEnabled = true;
  bool _isLoading = false;

  // Контроллеры для времени пробуждения
  final Map<String, TimeOfDay?> _wakeTimes = {
    'default': null,
    'weekdays': null,
    'weekends': null,
    'monday': null,
    'tuesday': null,
    'wednesday': null,
    'thursday': null,
    'friday': null,
    'saturday': null,
    'sunday': null,
  };

  @override
  void initState() {
    super.initState();
    _sleepService = SleepService(userId: widget.userId);
    _initializeFromCurrentSchedule();
  }

  /// Инициализирует состояние из текущего расписания
  void _initializeFromCurrentSchedule() {
    if (widget.currentSchedule != null) {
      final schedule = widget.currentSchedule!;
      _selectedType = schedule.scheduleType;
      _isEnabled = schedule.isEnabled;

      // Заполняем времена пробуждения
      _wakeTimes['default'] = _parseTime(schedule.defaultWakeTime);
      _wakeTimes['weekdays'] = _parseTime(schedule.weekdaysWakeTime);
      _wakeTimes['weekends'] = _parseTime(schedule.weekendsWakeTime);
      _wakeTimes['monday'] = _parseTime(schedule.mondayWakeTime);
      _wakeTimes['tuesday'] = _parseTime(schedule.tuesdayWakeTime);
      _wakeTimes['wednesday'] = _parseTime(schedule.wednesdayWakeTime);
      _wakeTimes['thursday'] = _parseTime(schedule.thursdayWakeTime);
      _wakeTimes['friday'] = _parseTime(schedule.fridayWakeTime);
      _wakeTimes['saturday'] = _parseTime(schedule.saturdayWakeTime);
      _wakeTimes['sunday'] = _parseTime(schedule.sundayWakeTime);
    }
  }

  /// Парсит строку времени в TimeOfDay
  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Ошибка парсинга времени: $timeString');
    }
    return null;
  }

  /// Форматирует TimeOfDay в строку
  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Показывает диалог выбора времени
  Future<void> _selectTime(String key) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeTimes[key] ?? const TimeOfDay(hour: 7, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _wakeTimes[key] = picked;
      });
    }
  }

  /// Сохраняет расписание
  Future<void> _saveSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dto = CreateSleepScheduleDto(
        scheduleType: _selectedType,
        isEnabled: _isEnabled,
        defaultWakeTime: _formatTime(_wakeTimes['default']),
        weekdaysWakeTime: _formatTime(_wakeTimes['weekdays']),
        weekendsWakeTime: _formatTime(_wakeTimes['weekends']),
        mondayWakeTime: _formatTime(_wakeTimes['monday']),
        tuesdayWakeTime: _formatTime(_wakeTimes['tuesday']),
        wednesdayWakeTime: _formatTime(_wakeTimes['wednesday']),
        thursdayWakeTime: _formatTime(_wakeTimes['thursday']),
        fridayWakeTime: _formatTime(_wakeTimes['friday']),
        saturdayWakeTime: _formatTime(_wakeTimes['saturday']),
        sundayWakeTime: _formatTime(_wakeTimes['sunday']),
      );

      final result = await _sleepService.createOrUpdateSleepSchedule(dto);
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Расписание сна успешно сохранено'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onScheduleUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка сохранения расписания'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Строит виджет выбора времени
  Widget _buildTimeSelector(String label, String key, {bool isRequired = false}) {
    final time = _wakeTimes[key];
    
    return ListTile(
      title: Text(label),
      subtitle: time != null 
        ? Text(time.format(context))
        : Text(isRequired ? 'Не выбрано (обязательно)' : 'Не выбрано'),
      trailing: const Icon(Icons.access_time),
      onTap: () => _selectTime(key),
    );
  }

  /// Строит контент для режима "Одинаковое время"
  Widget _buildSameTimeContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.recommend, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Рекомендуемый режим! Одинаковое время пробуждения каждый день улучшает качество сна.',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildTimeSelector('Время пробуждения', 'default', isRequired: true),
      ],
    );
  }

  /// Строит контент для режима "Будни и выходные"
  Widget _buildWeekdaysWeekendsContent() {
    return Column(
      children: [
        _buildTimeSelector('Будни (Пн-Пт)', 'weekdays', isRequired: true),
        _buildTimeSelector('Выходные (Сб-Вс)', 'weekends', isRequired: true),
      ],
    );
  }

  /// Строит контент для режима "Индивидуальное"
  Widget _buildIndividualContent() {
    final days = [
      ('Понедельник', 'monday'),
      ('Вторник', 'tuesday'),
      ('Среда', 'wednesday'),
      ('Четверг', 'thursday'),
      ('Пятница', 'friday'),
      ('Суббота', 'saturday'),
      ('Воскресенье', 'sunday'),
    ];

    return Column(
      children: days.map((day) => _buildTimeSelector(day.$1, day.$2)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Расписание сна',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isEnabled) ...[
              const Text(
                'Выберите режим расписания:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Радиокнопки для выбора типа расписания
              ...ScheduleType.values.map((type) => RadioListTile<ScheduleType>(
                title: Text(type.displayName),
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              )),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Контент в зависимости от выбранного типа
              if (_selectedType == ScheduleType.sameTime) 
                _buildSameTimeContent()
              else if (_selectedType == ScheduleType.weekdaysWeekends)
                _buildWeekdaysWeekendsContent()
              else
                _buildIndividualContent(),
              
              const SizedBox(height: 24),
              
              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Сохранить расписание',
                        style: TextStyle(fontSize: 16),
                      ),
                ),
              ),
            ] else ...[
              const Text(
                'Расписание сна отключено',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Сохранить настройки',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
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