import 'package:flutter/material.dart';

// Экран для выбора блюд для добавления в приём пищи
class DishSelectionScreen extends StatefulWidget {
  final String userId;
  final String mealId;

  const DishSelectionScreen({
    Key? key,
    required this.userId,
    required this.mealId,
  }) : super(key: key);

  @override
  State<DishSelectionScreen> createState() => _DishSelectionScreenState();
}

class _DishSelectionScreenState extends State<DishSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор блюд'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Экран выбора блюд',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будет реализован выбор блюд для приёма пищи',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 