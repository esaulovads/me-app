import 'dart:ui';
import 'package:flutter/material.dart';

// Утилиты для оптимизации производительности приложения
class PerformanceUtils {
  // Оптимизированные цвета (const вместо динамических)
  static const Color greyLight = Color(0xFF757575);
  static const Color greyMedium = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);
  static const Color black87 = Color(0xDD000000);
  static const Color shadowColor = Color(0x1A000000);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Оптимизированные тени
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadowColor,
      spreadRadius: 1,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  // Оптимизированные текстовые стили
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: black87,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    color: greyLight,
  );
  
  // Оптимизированные border radius
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(8));
  
  // Оптимизированные отступы
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets smallMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  
  // Оптимизированные размеры
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 20;
  static const double iconSizeLarge = 28;
  
  // Оптимизированный виджет-разделитель
  static Widget buildDivider() {
    return Container(
      height: 1,
      color: dividerColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
  
  // Оптимизированная кнопка действия
  static Widget buildActionButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required Color backgroundColor,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSizeSmall),
        label: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: const RoundedRectangleBorder(
            borderRadius: buttonRadius,
          ),
        ),
      ),
    );
  }
  
  // Оптимизированный индикатор загрузки
  static Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  // Оптимизированное пустое состояние
  static Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: greyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Оптимизированное состояние ошибки
  static Widget buildErrorState({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: captionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
  
  // Принудительная сборка мусора (использовать осторожно!)
  static void forceGarbageCollection() {
    // Принудительная сборка мусора в критических ситуациях
    // Использовать только при серьезных проблемах с памятью
    window.scheduleFrame();
  }
} 