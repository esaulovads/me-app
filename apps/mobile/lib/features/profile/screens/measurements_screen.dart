import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/onboarding_layout.dart';

class MeasurementsScreen extends StatefulWidget {
  final double? initialHeight;
  final double? initialWeight;
  final Function(double height, double weight) onMeasurementsSubmitted;
  final VoidCallback onBack;

  const MeasurementsScreen({
    Key? key,
    this.initialHeight,
    this.initialWeight,
    required this.onMeasurementsSubmitted,
    required this.onBack,
  }) : super(key: key);

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.initialHeight?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
    _validateInput();
    _heightController.addListener(_validateInput);
    _weightController.addListener(_validateInput);
  }

  void _validateInput() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    setState(() {
      _isValid = height != null && 
                 weight != null && 
                 height >= 100 && 
                 height <= 250 &&
                 weight >= 30 &&
                 weight <= 300;
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Укажите ваши параметры',
      child: Column(
        children: [
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Рост',
              hintText: 'Введите ваш рост в см',
              suffixText: 'см',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Вес',
              hintText: 'Введите ваш вес в кг',
              suffixText: 'кг',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
            ],
          ),
        ],
      ),
      onNext: _isValid 
        ? () { 
            FocusScope.of(context).unfocus();
            widget.onMeasurementsSubmitted(
              double.parse(_heightController.text),
              double.parse(_weightController.text)
            ); 
          }
        : null,
      onBack: widget.onBack,
    );
  }
} 