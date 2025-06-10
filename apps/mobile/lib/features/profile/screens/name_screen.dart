import 'package:flutter/material.dart';
import '../widgets/onboarding_layout.dart';

class NameScreen extends StatefulWidget {
  final String? initialName;
  final Function(String) onNameSubmitted;
  
  const NameScreen({
    Key? key,
    this.initialName,
    required this.onNameSubmitted,
  }) : super(key: key);

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _controller;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _validateInput(_controller.text);
    _controller.addListener(() => _validateInput(_controller.text));
  }

  void _validateInput(String value) {
    setState(() {
      _isValid = value.trim().length >= 2;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Как вас зовут?',
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Имя',
              hintText: 'Введите ваше имя',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
        ],
      ),
      onNext: _isValid 
        ? () { 
            // Скрываем клавиатуру перед переходом
            FocusScope.of(context).unfocus();
            widget.onNameSubmitted(_controller.text.trim()); 
          }
        : null,
    );
  }
} 