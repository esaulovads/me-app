// Утилита для форматирования дат на русском языке
class DateFormatter {
  // Названия месяцев на русском языке в родительном падеже
  static const List<String> _monthNames = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];

  // Названия дней недели на русском языке
  static const List<String> _dayNames = [
    'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'
  ];

  // Форматирование даты с учетом относительного положения к сегодняшнему дню
  static String formatDateRelative(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    // Сравниваем только даты, игнорируя время
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final tomorrowOnly = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    if (dateOnly == todayOnly) {
      return 'Сегодня: ${_formatDate(date)}';
    } else if (dateOnly == yesterdayOnly) {
      return 'Вчера: ${_formatDate(date)}';
    } else if (dateOnly == tomorrowOnly) {
      return 'Завтра: ${_formatDate(date)}';
    } else {
      // Для остальных дат показываем день недели и дату
      return _formatDateWithDayName(date);
    }
  }

  // Базовое форматирование даты в формате "13 июля"
  static String _formatDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]}';
  }

  // Форматирование даты с днем недели в формате "Среда: 20 августа"
  static String _formatDateWithDayName(DateTime date) {
    final dayName = _dayNames[date.weekday - 1]; // weekday: 1=понедельник, 7=воскресенье
    final formattedDate = _formatDate(date);
    return '$dayName: $formattedDate';
  }

  // Проверка, является ли дата сегодняшней
  static bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  // Проверка, является ли дата вчерашней
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  // Проверка, является ли дата завтрашней
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }
} 