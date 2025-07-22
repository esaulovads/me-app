import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';
import '../models/dish_model.dart';
import '../models/product_model.dart';
import 'product_picker_screen.dart';

// Экран создания нового рецепта/блюда
class CreateRecipeScreen extends StatefulWidget {
  final String userId;

  const CreateRecipeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final NutritionService _nutritionService;
  
  // Контроллер для названия
  final _nameController = TextEditingController();
  
  // Список ингредиентов
  final List<DishIngredientInput> _ingredients = [];
  
  bool _isLoading = false;
  String? _error;

  // Кэш для результата расчета КБЖУ (оптимизация производительности)
  Map<String, double>? _cachedNutrition;
  int _lastIngredientsHash = 0;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(userId: widget.userId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nutritionService.dispose();
    super.dispose();
  }

  // Валидация названия
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите название рецепта';
    }
    
    if (value.trim().length < 2) {
      return 'Название должно содержать минимум 2 символа';
    }
    
    if (value.trim().length > 100) {
      return 'Название слишком длинное (макс. 100 символов)';
    }
    
    return null;
  }

  // Добавление продукта в рецепт
  Future<void> _addIngredient() async {
    // Получаем список ID уже выбранных продуктов
    final excludedProductIds = _ingredients
        .map((ingredient) => ingredient.productId)
        .toList();
    
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPickerScreen(
          userId: widget.userId,
          excludedProductIds: excludedProductIds,
        ),
      ),
    );

    if (result != null) {
      final product = result['product'] as Product;
      final weight = result['weight'] as double;
      
      setState(() {
        _ingredients.add(DishIngredientInput.fromProduct(product, weight));
        _cachedNutrition = null; // Сбрасываем кэш
      });
    }
  }

  // Удаление ингредиента
  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _cachedNutrition = null; // Сбрасываем кэш
    });
  }

  // Редактирование веса ингредиента
  Future<void> _editIngredientWeight(int index) async {
    final ingredient = _ingredients[index];
    final currentWeight = ingredient.weight;
    
    final weight = await showDialog<double>(
      context: context,
      builder: (context) => _WeightEditDialog(
        productName: ingredient.product?.name ?? 'Продукт',
        currentWeight: currentWeight,
      ),
    );
    
    if (weight != null) {
      setState(() {
        _ingredients[index] = DishIngredientInput(
          productId: ingredient.productId,
          weight: weight,
          product: ingredient.product,
        );
        _cachedNutrition = null; // Сбрасываем кэш
      });
    }
  }

  // Расчет общего КБЖУ рецепта на 100г (с кэшированием)
  Map<String, double> _calculateNutritionPer100g() {
    // Вычисляем хэш ингредиентов для проверки изменений
    final currentHash = _ingredients.map((i) => '${i.productId}_${i.weight}').join('|').hashCode;
    
    // Если ингредиенты не изменились, возвращаем кэшированный результат
    if (_cachedNutrition != null && _lastIngredientsHash == currentHash) {
      return _cachedNutrition!;
    }
    
    if (_ingredients.isEmpty) {
      final result = {
        'calories': 0.0,
        'proteins': 0.0,
        'fats': 0.0,
        'carbs': 0.0,
        'totalWeight': 0.0,
      };
      _cachedNutrition = result;
      _lastIngredientsHash = currentHash;
      return result;
    }
    
    double totalWeight = 0;
    double totalCalories = 0;
    double totalProteins = 0;
    double totalFats = 0;
    double totalCarbs = 0;
    
    for (final ingredient in _ingredients) {
      final product = ingredient.product;
      if (product != null) {
        final weight = ingredient.weight;
        totalWeight += weight;
        
        // Рассчитываем КБЖУ для этого количества продукта
        final ratio = weight / 100;
        totalCalories += product.caloriesPer100g * ratio;
        totalProteins += product.proteinsPer100g * ratio;
        totalFats += product.fatsPer100g * ratio;
        totalCarbs += product.carbsPer100g * ratio;
      }
    }
    
    if (totalWeight == 0) {
      final result = {
        'calories': 0.0,
        'proteins': 0.0,
        'fats': 0.0,
        'carbs': 0.0,
        'totalWeight': 0.0,
      };
      _cachedNutrition = result;
      _lastIngredientsHash = currentHash;
      return result;
    }
    
    // Пересчитываем на 100г
    final ratio100g = 100 / totalWeight;
    
    final result = {
      'calories': totalCalories * ratio100g,
      'proteins': totalProteins * ratio100g,
      'fats': totalFats * ratio100g,
      'carbs': totalCarbs * ratio100g,
      'totalWeight': totalWeight,
    };
    
    // Кэшируем результат
    _cachedNutrition = result;
    _lastIngredientsHash = currentHash;
    return result;
  }

  // Сохранение рецепта
  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_ingredients.isEmpty) {
      setState(() {
        _error = 'Добавьте хотя бы один продукт в рецепт';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dish = await _nutritionService.createDish(
        name: _nameController.text.trim(),
        ingredients: _ingredients,
      );

      if (mounted) {
        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Рецепт "${dish.name}" создан успешно'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Возвращаемся к списку рецептов с флагом обновления
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

  // Виджет ингредиента
  Widget _buildIngredientCard(DishIngredientInput ingredient, int index) {
    final product = ingredient.product;
    if (product == null) return const SizedBox.shrink();
    
    return RepaintBoundary(
      key: ValueKey('ingredient_${ingredient.productId}_${ingredient.weight}'),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(
            product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${ingredient.weight.toInt()} г • ${product.formattedNutrition}',
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editIngredientWeight(index),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Изменить вес',
              ),
              IconButton(
                onPressed: () => _removeIngredient(index),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет сводки КБЖУ
  Widget _buildNutritionSummary() {
    final nutrition = _calculateNutritionPer100g();
    
    return RepaintBoundary(
      key: const ValueKey('nutrition_summary'),
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Пищевая ценность рецепта на 100г:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientColumn('Калории', nutrition['calories']!, 'ккал'),
                  _buildNutrientColumn('Белки', nutrition['proteins']!, 'г'),
                  _buildNutrientColumn('Жиры', nutrition['fats']!, 'г'),
                  _buildNutrientColumn('Углеводы', nutrition['carbs']!, 'г'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Общий вес рецепта: ${nutrition['totalWeight']!.toInt()} г',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Колонка нутриента
  Widget _buildNutrientColumn(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать рецепт'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка сохранения в AppBar
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название рецепта
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название рецепта',
                          hintText: 'Например: Куриное филе с рисом',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isLoading,
                        validator: _validateName,
                        textCapitalization: TextCapitalization.words,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Заголовок ингредиентов
                      RepaintBoundary(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ингредиенты:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _addIngredient,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Добавить'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Список ингредиентов
                      _buildIngredientsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Сводка КБЖУ
                      if (_ingredients.isNotEmpty) _buildNutritionSummary(),
                      
                      _buildErrorSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Кнопка сохранения внизу
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // Секция ингредиентов (вынесена отдельно для оптимизации)
  Widget _buildIngredientsSection() {
    if (_ingredients.isEmpty) {
      return RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Добавьте продукты в рецепт',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _ingredients.asMap().entries.map((entry) {
        return _buildIngredientCard(entry.value, entry.key);
      }).toList(),
    );
  }

  // Секция ошибок
  Widget _buildErrorSection() {
    if (_error == null) return const SizedBox.shrink();
    
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(top: 16),
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
    );
  }

  // Нижняя кнопка
  Widget _buildBottomButton() {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRecipe,
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
                    'Создать рецепт',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Отдельный виджет для диалога редактирования веса
class _WeightEditDialog extends StatefulWidget {
  final String productName;
  final double currentWeight;

  const _WeightEditDialog({
    required this.productName,
    required this.currentWeight,
  });

  @override
  State<_WeightEditDialog> createState() => _WeightEditDialogState();
}

class _WeightEditDialogState extends State<_WeightEditDialog> {
  late final TextEditingController _weightController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.currentWeight.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final newWeight = double.tryParse(_weightController.text.trim());
    if (newWeight == null || newWeight <= 0) {
      setState(() {
        _errorText = 'Введите корректный вес больше 0';
      });
      return;
    }
    if (newWeight > 10000) {
      setState(() {
        _errorText = 'Вес слишком большой (макс. 10000г)';
      });
      return;
    }
    Navigator.pop(context, newWeight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Изменить вес: ${widget.productName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Вес в граммах',
              suffixText: 'г',
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            autofocus: true,
            onSubmitted: (_) => _validateAndSubmit(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
} 