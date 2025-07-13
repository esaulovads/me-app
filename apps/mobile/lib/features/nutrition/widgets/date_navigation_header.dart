import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';

class DateNavigationHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onDateTap;

  const DateNavigationHeader({
    Key? key,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
      height: MediaQuery.of(context).size.height * 0.1, // 10% от высоты экрана
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Стрелка влево
          IconButton(
            onPressed: onPreviousDay,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black87,
            ),
            iconSize: 24,
          ),
          
          // Центральная часть с иконкой календаря и датой
          Expanded(
            child: GestureDetector(
              onTap: onDateTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Иконка календаря
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    
                    // Текст с датой
                    Text(
                      DateFormatter.formatDateRelative(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Стрелка вправо
          IconButton(
            onPressed: onNextDay,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black87,
            ),
            iconSize: 24,
          ),
        ],
      ),
    ),
    );
  }
} 