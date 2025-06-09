import 'package:flutter/material.dart';
import '../widgets/onboarding_layout.dart';

class BirthDateScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onBack;

  const BirthDateScreen({
    Key? key,
    this.initialDate,
    required this.onDateSelected,
    required this.onBack,
  }) : super(key: key);

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Когда вы родились?',
      child: Column(
        children: [
          InkWell(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedDate != null 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _selectedDate != null 
                    ? _formatDate(_selectedDate!)
                    : 'Выберите дату рождения',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _selectedDate != null 
                      ? Theme.of(context).primaryColor 
                      : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      onNext: _selectedDate != null 
        ? () { widget.onDateSelected(_selectedDate!); }
        : null,
      onBack: widget.onBack,
    );
  }
} 