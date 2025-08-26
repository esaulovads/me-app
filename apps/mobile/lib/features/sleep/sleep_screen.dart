import 'dart:async';
import 'package:flutter/material.dart';
import 'models/sleep_schedule_model.dart';
import 'models/sleep_session_model.dart';
import 'services/sleep_service.dart';
import 'widgets/sleep_schedule_settings.dart';
import 'widgets/next_wake_time_display.dart';
import 'widgets/add_sleep_period_modal.dart';
import 'screens/sleep_schedule_edit_screen.dart';
import '../nutrition/widgets/date_navigation_header.dart';

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

class _SleepScreenState extends State<SleepScreen>
    with AutomaticKeepAliveClientMixin { // Сохраняем состояние экрана
  late SleepService _sleepService;
  SleepSchedule? _currentSchedule;
  DateTime _selectedDate = DateTime.now(); // Выбранная дата для просмотра данных сна
  
  // Кэш для данных сна
  final Map<String, List<SleepSession>> _sleepSessionsCache = {};
  final Map<String, double> _sleepDurationCache = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  bool _serviceAvailable = true;
  
  // Debounce для предотвращения частых запросов при быстрой смене дат
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true; // Сохраняем состояние экрана
  
  @override
  void initState() {
    super.initState();
    _sleepService = SleepService(userId: widget.userId);
    _loadCurrentSchedule();
    _loadDataForDate(_selectedDate); // Загружаем данные сна для выбранной даты
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _sleepService.dispose();
    super.dispose();
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

  // === Методы для работы с датами и данными сна ===

  /// Ленивая загрузка данных сна для выбранной даты
  Future<void> _loadDataForDate(DateTime date, {bool forceReload = false}) async {
    final dateKey = _formatDateKey(date);
    
    // Если данные уже в кэше и не требуется принудительная перезагрузка, не загружаем повторно
    if (!forceReload && _sleepSessionsCache.containsKey(dateKey) && _sleepDurationCache.containsKey(dateKey)) {
      return;
    }

    // Отменяем предыдущий таймер
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async { // Увеличил debounce до 500ms
      if (!mounted) return;
      
      try {
        final dateString = dateKey; // Используем тот же формат
        
        // Загружаем данные параллельно
        final results = await Future.wait([
          _sleepService.getSleepSessionsByDate(dateString),
          _sleepService.getTotalSleepDuration(dateString),
        ]);

        if (mounted) {
          // Кэшируем результаты
          _sleepSessionsCache[dateKey] = results[0] as List<SleepSession>;
          _sleepDurationCache[dateKey] = results[1] as double;
          
          // Минимальное обновление состояния, только если это текущая дата
          if (_formatDateKey(_selectedDate) == dateKey) {
            // Используем минимальный setState для конкретного обновления
            if (mounted) {
              setState(() {
                // Только триггерим изменение, без лишних пересчетов
              });
            }
          }
        }
      } catch (e) {
        print('Ошибка загрузки данных сна для $dateKey: $e');
        // В случае ошибки устанавливаем пустые данные
        if (mounted) {
          _sleepSessionsCache[dateKey] = [];
          _sleepDurationCache[dateKey] = 0.0;
        }
      }
    });
  }

  /// Форматирование даты для ключа кэша
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Переход к предыдущему дню
  void _goToPreviousDay() {
    final newDate = _selectedDate.subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = newDate;
    });
    _loadDataForDate(newDate);
  }

  /// Переход к следующему дню
  void _goToNextDay() {
    final newDate = _selectedDate.add(const Duration(days: 1));
    setState(() {
      _selectedDate = newDate;
    });
    _loadDataForDate(newDate);
  }

  /// Открытие датапикера для выбора конкретной даты
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ru', 'RU'),
      helpText: 'Выберите дату',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _loadDataForDate(pickedDate);
    }
  }

  /// Получение кэшированных сессий сна для выбранной даты
  List<SleepSession> _getCachedSleepSessions() {
    final dateKey = _formatDateKey(_selectedDate);
    return _sleepSessionsCache[dateKey] ?? [];
  }

  /// Получение кэшированной продолжительности сна для выбранной даты
  double _getCachedSleepDuration() {
    final dateKey = _formatDateKey(_selectedDate);
    return _sleepDurationCache[dateKey] ?? 0.0;
  }



  /// Открывает экран редактирования расписания
  Future<void> _openScheduleEditScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SleepScheduleEditScreen(
          userId: widget.userId,
          currentSchedule: _currentSchedule,
        ),
      ),
    );

    // Если расписание было изменено, перезагружаем данные
    if (result == true) {
      _loadCurrentSchedule();
    }
  }

  /// Повторная попытка загрузки
  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadCurrentSchedule();
    _loadDataForDate(_selectedDate, forceReload: true);
  }

  /// Открывает модалку для добавления нового периода сна
  Future<void> _openAddSleepPeriodModal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddSleepPeriodModal(
        selectedDate: _selectedDate,
        onSave: _createOrUpdateSleepPeriod,
      ),
    );

    // Если период был успешно создан, обновляем данные
    if (result == true) {
      // Очищаем кэш для принудительной перезагрузки
      final dateKey = _formatDateKey(_selectedDate);
      _sleepSessionsCache.remove(dateKey);
      _sleepDurationCache.remove(dateKey);
      
      _loadDataForDate(_selectedDate, forceReload: true);
    }
  }

  /// Открывает модалку для редактирования периода сна
  Future<void> _openEditSleepPeriodModal(SleepSession session) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddSleepPeriodModal(
        selectedDate: _selectedDate,
        onSave: _createOrUpdateSleepPeriod,
        existingSession: session,
      ),
    );

    // Если период был успешно обновлен, обновляем данные
    if (result == true) {
      // Очищаем кэш для принудительной перезагрузки
      final dateKey = _formatDateKey(_selectedDate);
      _sleepSessionsCache.remove(dateKey);
      _sleepDurationCache.remove(dateKey);
      
      _loadDataForDate(_selectedDate, forceReload: true);
    }
  }

  /// Создает новый период сна или обновляет существующий
  Future<void> _createOrUpdateSleepPeriod(DateTime sleepTime, DateTime wakeTime, [String? sessionId]) async {
    try {
      SleepSession? sleepSession;
      
      if (sessionId != null) {
        // Обновляем существующий период
        sleepSession = await _sleepService.updateSleepSession(
          sessionId: sessionId,
          sleepTime: sleepTime,
          wakeTime: wakeTime,
        );
        
        if (sleepSession != null) {
          print('Период сна успешно обновлен: ${sleepSession.durationHours.toStringAsFixed(1)} ч');
        } else {
          throw Exception('Не удалось обновить период сна');
        }
      } else {
        // Создаем новый период
        sleepSession = await _sleepService.createSleepSession(
          sleepTime: sleepTime,
          wakeTime: wakeTime,
        );
        
        if (sleepSession != null) {
          print('Период сна успешно создан: ${sleepSession.durationHours.toStringAsFixed(1)} ч');
        } else {
          throw Exception('Не удалось создать период сна');
        }
      }
    } catch (e) {
      print('Ошибка создания/обновления периода сна: $e');
      rethrow; // Передаем ошибку в модалку для отображения
    }
  }

  /// Удаляет период сна с подтверждением
  Future<void> _deleteSleepPeriod(SleepSession session) async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление периода сна'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вы уверены, что хотите удалить этот период сна?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.sleepTime.hour.toString().padLeft(2, '0')}:${session.sleepTime.minute.toString().padLeft(2, '0')} — ${session.wakeTime.hour.toString().padLeft(2, '0')}:${session.wakeTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Продолжительность: ${session.durationHours.toStringAsFixed(1)} ч',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Это действие нельзя отменить.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _sleepService.deleteSleepSession(session.id);
        
        if (success) {
          print('Период сна успешно удален');
          // Очищаем кэш для принудительной перезагрузки
          final dateKey = _formatDateKey(_selectedDate);
          _sleepSessionsCache.remove(dateKey);
          _sleepDurationCache.remove(dateKey);
          
          // Обновляем данные
          _loadDataForDate(_selectedDate, forceReload: true);
          
          // Показываем уведомление об успехе
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Период сна удален'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Не удалось удалить период сна');
        }
      } catch (e) {
        print('Ошибка удаления периода сна: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Виджет для отображения данных сна за выбранную дату
  Widget _buildSleepDataContent() {
    final sleepSessions = _getCachedSleepSessions();
    final totalDuration = _getCachedSleepDuration();
    
    return RepaintBoundary(
      child: Column(
        children: [
          // Карточка с общей информацией о сне за день
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bedtime, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Сон за ${_selectedDate.day}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Общая продолжительность сна
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Общая продолжительность: ${totalDuration.toStringAsFixed(1)} ч',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Количество периодов сна
                  Row(
                    children: [
                      const Icon(Icons.hotel, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Периодов сна: ${sleepSessions.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Кнопка добавления периода сна
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openAddSleepPeriodModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить период сна'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
          
          // Список периодов сна
          if (sleepSessions.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Периоды сна',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            ...sleepSessions.map((session) => _buildSleepSessionCard(session)).toList(),
          ] else ...[
            // Пустое состояние
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bedtime_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Нет данных о сне',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'За выбранную дату нет записей о сне',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openAddSleepPeriodModal,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить период сна'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Карточка для отображения отдельной сессии сна
  Widget _buildSleepSessionCard(SleepSession session) {
    return RepaintBoundary( // Добавляем RepaintBoundary для изоляции перерисовок
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
            // Иконка
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hotel,
                color: Colors.indigo,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Информация о сессии
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.sleepTime.hour.toString().padLeft(2, '0')}:${session.sleepTime.minute.toString().padLeft(2, '0')} — ${session.wakeTime.hour.toString().padLeft(2, '0')}:${session.wakeTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Продолжительность: ${session.durationHours.toStringAsFixed(1)} ч',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Кнопки действий
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Кнопка редактирования
                IconButton(
                  onPressed: () => _openEditSleepPeriodModal(session),
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  tooltip: 'Редактировать',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: const EdgeInsets.all(4),
                ),
                
                // Кнопка удаления
                IconButton(
                  onPressed: () => _deleteSleepPeriod(session),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Удалить',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Необходимо для AutomaticKeepAliveClientMixin
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
                Text('Загрузка данных сна...'),
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
          : Column(
              children: [
                // Заголовок с навигацией по датам
                RepaintBoundary(
                  child: DateNavigationHeader(
                    selectedDate: _selectedDate,
                    onPreviousDay: _goToPreviousDay,
                    onNextDay: _goToNextDay,
                    onDateTap: _selectDate,
                  ),
                ),
                
                // Основное содержимое экрана
                Expanded(
                  child: SingleChildScrollView(
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
                        
                        // Блок расписания сна (только если сервис доступен)
                        if (_serviceAvailable) ...[
                          // Если расписание уже настроено, показываем время пробуждения
                          if (_currentSchedule != null)
                            NextWakeTimeDisplay(
                              schedule: _currentSchedule!,
                              onEditPressed: _openScheduleEditScreen,
                              userId: widget.userId,
                              selectedDate: _selectedDate, // Передаем выбранную дату
                            )
                          // Если расписание не настроено, показываем настройки
                          else
                            SleepScheduleSettings(
                              userId: widget.userId,
                              currentSchedule: _currentSchedule,
                              onScheduleUpdated: _onScheduleUpdated,
                            ),
                        ],
                        
                        // Данные сна за выбранную дату
                        _buildSleepDataContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

} 