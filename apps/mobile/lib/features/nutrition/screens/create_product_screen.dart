import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/nutrition_service.dart';
import '../models/product_model.dart';

// Экран создания нового продукта
class CreateProductScreen extends StatefulWidget {
  final String userId;

  const CreateProductScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final NutritionService _nutritionService;
  
  // Контроллеры для полей ввода
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();
  final _servingWeightController = TextEditingController(text: '100'); // По умолчанию 100г
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(userId: widget.userId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    _servingWeightController.dispose();
    _nutritionService.dispose();
    super.dispose();
  }

  // Валидация числового поля
  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите $fieldName';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Введите корректное число';
    }
    
    if (number < 0) {
      return '$fieldName не может быть отрицательным';
    }
    
    if (number > 1000) {
      return '$fieldName слишком большое (макс. 1000)';
    }
    
    return null;
  }

  // Валидация названия
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите название продукта';
    }
    
    if (value.trim().length < 2) {
      return 'Название должно содержать минимум 2 символа';
    }
    
    if (value.trim().length > 100) {
      return 'Название слишком длинное (макс. 100 символов)';
    }
    
    return null;
  }

  // Сохранение продукта
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await _nutritionService.createProduct(
        name: _nameController.text.trim(),
        caloriesPer100g: double.parse(_caloriesController.text.trim()),
        proteinsPer100g: double.parse(_proteinsController.text.trim()),
        fatsPer100g: double.parse(_fatsController.text.trim()),
        carbsPer100g: double.parse(_carbsController.text.trim()),
        servingWeight: double.parse(_servingWeightController.text.trim()),
      );

      if (mounted) {
        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Продукт "${product.name}" создан успешно'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Возвращаемся к списку продуктов с флагом обновления
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Построение поля ввода числа
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        enabled: !_isLoading,
      ),
      validator: (value) => _validateNumber(value, label.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать продукт'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка сохранения в AppBar
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: const Text(
              'Сохранить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название продукта
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название продукта',
                  hintText: 'Например: Куриная грудка',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 24),
              
              // Заголовок КБЖУ
              const Text(
                'Пищевая ценность на 100 грамм:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Калории
              _buildNumberField(
                controller: _caloriesController,
                label: 'Калории',
                hint: '0',
                suffix: 'ккал',
              ),
              
              const SizedBox(height: 16),
              
              // Белки
              _buildNumberField(
                controller: _proteinsController,
                label: 'Белки',
                hint: '0',
                suffix: 'г',
              ),
              
              const SizedBox(height: 16),
              
              // Жиры
              _buildNumberField(
                controller: _fatsController,
                label: 'Жиры',
                hint: '0',
                suffix: 'г',
              ),
              
              const SizedBox(height: 16),
              
              // Углеводы
              _buildNumberField(
                controller: _carbsController,
                label: 'Углеводы',
                hint: '0',
                suffix: 'г',
              ),
              
              const SizedBox(height: 24),
              
              // Заголовок порции
              const Text(
                'Размер стандартной порции:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Укажите вес одной порции продукта для удобства выбора',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Вес порции
              _buildNumberField(
                controller: _servingWeightController,
                label: 'Вес порции',
                hint: '100',
                suffix: 'г',
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Создать продукт',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 