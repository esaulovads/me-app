import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Модальное окно для ввода веса продукта или блюда с кнопками быстрого изменения веса
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
  
  // Текущий вес в граммах
  double _currentWeight = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Устанавливаем значение по умолчанию: defaultWeight или 100г
    _currentWeight = widget.defaultWeight ?? 100.0;
    _weightController.text = _currentWeight.toInt().toString();
    
    // Слушаем изменения в поле ввода
    _weightController.addListener(_onTextChanged);
    
    // Автофокус на поле ввода
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _weightController.removeListener(_onTextChanged);
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Обработка изменений в текстовом поле
  void _onTextChanged() {
    final text = _weightController.text.trim();
    if (text.isEmpty) {
      _currentWeight = 0.0;
    } else {
      final weight = double.tryParse(text);
      if (weight != null && weight >= 0) {
        _currentWeight = weight;
      }
    }
    _validateWeight();
  }

  // Валидация введенного веса
  bool _validateWeight() {
    if (_currentWeight <= 0) {
      setState(() {
        _error = 'Вес должен быть больше 0';
      });
      return false;
    }

    if (_currentWeight > 10000) {
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

  // Изменение веса на заданное количество граммов
  void _changeWeight(int grams) {
    double newWeight = _currentWeight + grams;
    
    // Ограничиваем минимальный вес нулём
    if (newWeight < 0) {
      newWeight = 0;
    }
    
    // Ограничиваем максимальный вес
    if (newWeight > 10000) {
      newWeight = 10000;
    }
    
    _currentWeight = newWeight;
    _weightController.text = newWeight == 0 ? '' : newWeight.toInt().toString();
    _validateWeight();
  }

  // Подтверждение ввода
  void _confirm() {
    if (!_validateWeight()) return;

    setState(() {
      _isLoading = true;
    });

    Navigator.of(context).pop(_currentWeight);
  }

  // Отмена
  void _cancel() {
    Navigator.of(context).pop();
  }

  // Установка стандартного веса (для продуктов)
  void _setDefaultWeight() {
    if (widget.defaultWeight != null) {
      _currentWeight = widget.defaultWeight!;
      _weightController.text = _currentWeight.toInt().toString();
      _validateWeight();
    }
  }

  // Виджет кнопки изменения веса
  Widget _buildWeightButton({
    required String label,
    required int grams,
    required bool isDecrease,
  }) {
    final isEnabled = !_isLoading && 
        (isDecrease ? _currentWeight > 0 : _currentWeight < 10000);
    
    return SizedBox(
      width: 50,
      height: 36,
      child: OutlinedButton(
        onPressed: isEnabled ? () => _changeWeight(grams) : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isEnabled ? Theme.of(context).primaryColor : Colors.grey[400]!,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isEnabled ? Theme.of(context).primaryColor : Colors.grey[400],
          ),
        ),
      ),
    );
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
              width: double.infinity, // Делаем блок на всю ширину
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
            
            // Поле ввода веса с кнопками
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
                
                // Основной ряд с кнопками уменьшения, полем ввода и кнопками увеличения
                Row(
                  children: [
                    // Кнопки уменьшения веса
                    Column(
                      children: [
                        _buildWeightButton(
                          label: '-5',
                          grams: -5,
                          isDecrease: true,
                        ),
                        const SizedBox(height: 4),
                        _buildWeightButton(
                          label: '-50',
                          grams: -50,
                          isDecrease: true,
                        ),
                        const SizedBox(height: 4),
                        _buildWeightButton(
                          label: '-100',
                          grams: -100,
                          isDecrease: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Поле ввода веса
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
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '100',
                          suffixText: 'г',
                          border: const OutlineInputBorder(),
                          errorText: _error,
                          enabled: !_isLoading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (_) => _confirm(),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Кнопки увеличения веса
                    Column(
                      children: [
                        _buildWeightButton(
                          label: '+5',
                          grams: 5,
                          isDecrease: false,
                        ),
                        const SizedBox(height: 4),
                        _buildWeightButton(
                          label: '+50',
                          grams: 50,
                          isDecrease: false,
                        ),
                        const SizedBox(height: 4),
                        _buildWeightButton(
                          label: '+100',
                          grams: 100,
                          isDecrease: false,
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Кнопка "Порция" для продуктов (если есть стандартный вес)
                if (widget.defaultWeight != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _setDefaultWeight,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: Text(
                        'Порция (${widget.defaultWeight!.toInt()}г)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
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
                  onPressed: (_isLoading || _currentWeight <= 0) ? null : _confirm,
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