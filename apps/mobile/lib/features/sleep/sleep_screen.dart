import 'package:flutter/material.dart';

/// Экран управления сном (заглушка)
class SleepScreen extends StatelessWidget {
  final String userId;

  const SleepScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сон'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bedtime,
              size: 64,
              color: Colors.indigo,
            ),
            SizedBox(height: 16),
            Text(
              'Экран управления сном',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
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
    );
  }
} 