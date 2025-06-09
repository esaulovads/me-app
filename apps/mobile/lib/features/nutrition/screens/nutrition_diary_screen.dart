import 'package:flutter/material.dart';

class NutritionDiaryScreen extends StatelessWidget {
  final String userId;

  const NutritionDiaryScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник питания'),
      ),
      body: const Center(
        child: Text('Здесь будет дневник питания'),
      ),
    );
  }
} 