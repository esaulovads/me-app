import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Модальное окно для ввода веса продукта или блюда
class WeightInputModal extends StatefulWidget {
  final String itemName;
  final String itemType; // "продукт" или "блюдо"
  final String nutritionInfo; // информация о КБЖУ на 100г
  final double? defaultWeight; // стандартный вес (для продуктов - размер порции)

  const WeightInputModal({
    Key? key,
    required this.itemName,
    required this.itemType,
    required this.nutritionInfo,
    this.defaultWeight,
  }) : super(key: key);

  @override
  State<WeightInputModal> createState() => _WeightInputModalState();
}

class _WeightInputModalState extends State<WeightInputModal> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Устанавливаем значение по умолчанию, если есть
    if (widget.defaultWeight != null) {
      _weightController.text = widget.defaultWeight!.toInt().toString();
    }
    
    // Автофокус на поле ввода
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Валидация введенного веса
  bool _validateWeight() {
    final text = _weightController.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _error = 'Введите вес';
      });
      return false;
    }

    final weight = double.tryParse(text);
    if (weight == null) {
      setState(() {
        _error = 'Введите корректное число';
      });
      return false;
    }

    if (weight <= 0) {
      setState(() {
        _error = 'Вес должен быть больше 0';
      });
      return false;
    }

    if (weight > 10000) {
      setState(() {
        _error = 'Максимальный вес 10000г';
      });
      return false;
    }

    setState(() {
      _error = null;
    });
    return true;
  }

  // Подтверждение ввода
  void _confirm() {
    if (!_validateWeight()) return;

    setState(() {
      _isLoading = true;
    });

    final weight = double.parse(_weightController.text.trim());
    Navigator.of(context).pop(weight);
  }

  // Отмена
  void _cancel() {
    Navigator.of(context).pop();
  }

  // Установка стандартного веса (для продуктов)
  void _setDefaultWeight() {
    if (widget.defaultWeight != null) {
      _weightController.text = widget.defaultWeight!.toInt().toString();
      _validateWeight();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Добавить ${widget.itemType}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Название продукта/блюда
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.nutritionInfo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Поле ввода веса
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Вес в граммах:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        focusNode: _focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Введите вес',
                          suffixText: 'г',
                          border: const OutlineInputBorder(),
                          errorText: _error,
                          enabled: !_isLoading,
                        ),
                        onChanged: (_) => _validateWeight(),
                        onSubmitted: (_) => _confirm(),
                      ),
                    ),
                    
                    // Кнопка "Порция" для продуктов
                    if (widget.defaultWeight != null) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _setDefaultWeight,
                        child: Text(
                          '${widget.defaultWeight!.toInt()}г\n(порция)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _cancel,
                  child: const Text('Отмена'),
                ),
                
                const SizedBox(width: 12),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Добавить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Вспомогательная функция для показа модального окна
Future<double?> showWeightInputModal({
  required BuildContext context,
  required String itemName,
  required String itemType,
  required String nutritionInfo,
  double? defaultWeight,
}) async {
  return showDialog<double>(
    context: context,
    barrierDismissible: false, // Не закрывать по нажатию вне диалога
    builder: (context) => WeightInputModal(
      itemName: itemName,
      itemType: itemType,
      nutritionInfo: nutritionInfo,
      defaultWeight: defaultWeight,
    ),
  );
} 