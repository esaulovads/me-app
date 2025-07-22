import 'dart:async';
import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';
import '../models/product_model.dart';
import '../models/dish_model.dart';
import '../widgets/weight_input_modal.dart';
import '../utils/performance_utils.dart';
import 'create_product_screen.dart';
import 'create_recipe_screen.dart';

// Экран для выбора продуктов и рецептов для добавления в приём пищи
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

class _DishSelectionScreenState extends State<DishSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final NutritionService _nutritionService;
  late final TabController _tabController;
  
  // Контроллеры для поиска
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _productsScrollController = ScrollController();
  final ScrollController _dishesScrollController = ScrollController();
  
  // Состояние загрузки и данные
  bool _isLoadingProducts = false;
  bool _isLoadingDishes = false;
  bool _isLoadingMoreProducts = false;
  bool _isLoadingMoreDishes = false;
  String? _errorProducts;
  String? _errorDishes;
  
  // Данные продуктов
  List<Product> _products = [];
  List<Product> _recentProducts = [];
  int _totalProducts = 0;
  int _currentProductsOffset = 0;
  
  // Данные блюд
  List<Dish> _dishes = [];
  List<Dish> _recentDishes = [];
  int _totalDishes = 0;
  int _currentDishesOffset = 0;
  
  // Поисковые запросы
  String _currentSearchQuery = '';
  Timer? _searchDebounce;
  
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(userId: widget.userId);
    _tabController = TabController(length: 2, vsync: this);
    
    // Загружаем начальные данные
    _loadInitialData();
    
    // Настраиваем слушатели для пагинации
    _productsScrollController.addListener(_onProductsScroll);
    _dishesScrollController.addListener(_onDishesScroll);
    
    // Настраиваем слушатель поиска
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _productsScrollController.dispose();
    _dishesScrollController.dispose();
    _searchDebounce?.cancel();
    _nutritionService.dispose();
    super.dispose();
  }

  // Загрузка начальных данных
  Future<void> _loadInitialData() async {
    // Загружаем данные для обеих вкладок параллельно
    await Future.wait([
      _loadProducts(isInitial: true),
      _loadDishes(isInitial: true),
      _loadRecentItems(),
    ]);
  }

  // Загрузка недавних элементов
  Future<void> _loadRecentItems() async {
    try {
      final results = await Future.wait([
        _nutritionService.getRecentProducts(),
        _nutritionService.getRecentDishes(),
      ]);
      
      if (mounted) {
        setState(() {
          _recentProducts = results[0] as List<Product>;
          _recentDishes = results[1] as List<Dish>;
        });
      }
    } catch (e) {
      // Если не удалось загрузить недавние элементы, продолжаем без них
      print('Не удалось загрузить недавние элементы: $e');
    }
  }

  // Загрузка продуктов
  Future<void> _loadProducts({bool isInitial = false, bool isLoadMore = false}) async {
    if (_isLoadingProducts || (_isLoadingMoreProducts && isLoadMore)) return;

    if (mounted) {
      setState(() {
        if (isInitial) {
          _isLoadingProducts = true;
          _errorProducts = null;
          _products.clear();
          _currentProductsOffset = 0;
        } else if (isLoadMore) {
          _isLoadingMoreProducts = true;
        }
      });
    }

    try {
      final response = await _nutritionService.getProducts(
        limit: _pageSize,
        offset: isLoadMore ? _currentProductsOffset : 0,
        search: _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
      );

      if (mounted) {
        setState(() {
          if (isInitial || !isLoadMore) {
            _products = response.products;
            _currentProductsOffset = response.products.length;
          } else {
            _products.addAll(response.products);
            _currentProductsOffset += response.products.length;
          }
          
          _totalProducts = response.total;
          _isLoadingProducts = false;
          _isLoadingMoreProducts = false;
          _errorProducts = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _isLoadingMoreProducts = false;
          _errorProducts = e.toString();
        });
      }
    }
  }

  // Загрузка блюд
  Future<void> _loadDishes({bool isInitial = false, bool isLoadMore = false}) async {
    if (_isLoadingDishes || (_isLoadingMoreDishes && isLoadMore)) return;

    if (mounted) {
      setState(() {
        if (isInitial) {
          _isLoadingDishes = true;
          _errorDishes = null;
          _dishes.clear();
          _currentDishesOffset = 0;
        } else if (isLoadMore) {
          _isLoadingMoreDishes = true;
        }
      });
    }

    try {
      final response = await _nutritionService.getDishes(
        limit: _pageSize,
        offset: isLoadMore ? _currentDishesOffset : 0,
        search: _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
      );

      if (mounted) {
        setState(() {
          if (isInitial || !isLoadMore) {
            _dishes = response.dishes;
            _currentDishesOffset = response.dishes.length;
          } else {
            _dishes.addAll(response.dishes);
            _currentDishesOffset += response.dishes.length;
          }
          
          _totalDishes = response.total;
          _isLoadingDishes = false;
          _isLoadingMoreDishes = false;
          _errorDishes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDishes = false;
          _isLoadingMoreDishes = false;
          _errorDishes = e.toString();
        });
      }
    }
  }

  // Обработка изменения поискового запроса
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query != _currentSearchQuery) {
        setState(() {
          _currentSearchQuery = query;
        });
        
        // Перезагружаем данные с новым поисковым запросом
        _loadProducts(isInitial: true);
        _loadDishes(isInitial: true);
      }
    });
  }

  // Обработка прокрутки списка продуктов для пагинации
  void _onProductsScroll() {
    if (_productsScrollController.position.pixels >= 
        _productsScrollController.position.maxScrollExtent - 200) {
      if (_currentProductsOffset < _totalProducts && !_isLoadingMoreProducts) {
        _loadProducts(isLoadMore: true);
      }
    }
  }

  // Обработка прокрутки списка блюд для пагинации
  void _onDishesScroll() {
    if (_dishesScrollController.position.pixels >= 
        _dishesScrollController.position.maxScrollExtent - 200) {
      if (_currentDishesOffset < _totalDishes && !_isLoadingMoreDishes) {
        _loadDishes(isLoadMore: true);
      }
    }
  }

  // Обработка выбора продукта
  Future<void> _onProductSelected(Product product) async {
    // Показываем модальное окно для ввода веса
    final weight = await showWeightInputModal(
      context: context,
      itemName: product.name,
      itemType: 'продукт',
      nutritionInfo: product.formattedNutrition,
      defaultWeight: product.servingWeight,
    );

    if (weight == null) return; // Пользователь отменил

    // Показываем индикатор загрузки
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Добавляем продукт в приём пищи
      await _nutritionService.addProductToMeal(widget.mealId, product.id, weight);
      
      if (mounted) {
        // Закрываем индикатор загрузки
        Navigator.of(context).pop();
        
        // Возвращаемся на экран питания с обновлением данных
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Закрываем индикатор загрузки
        Navigator.of(context).pop();
        
        // Показываем ошибку
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Обработка выбора блюда
  Future<void> _onDishSelected(Dish dish) async {
    // Показываем модальное окно для ввода веса
    final weight = await showWeightInputModal(
      context: context,
      itemName: dish.name,
      itemType: 'блюдо',
      nutritionInfo: dish.formattedNutrition,
    );

    if (weight == null) return; // Пользователь отменил

    // Показываем индикатор загрузки
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Добавляем блюдо в приём пищи
      await _nutritionService.addDishToMeal(widget.mealId, dish.id, weight);
      
      if (mounted) {
        // Закрываем индикатор загрузки
        Navigator.of(context).pop();
        
        // Возвращаемся на экран питания с обновлением данных
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Закрываем индикатор загрузки
        Navigator.of(context).pop();
        
        // Показываем ошибку
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Навигация к экрану создания продукта
  Future<void> _navigateToCreateProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProductScreen(userId: widget.userId),
      ),
    );

    // Если продукт был создан, обновляем список продуктов
    if (result == true) {
      _loadProducts(isInitial: true);
    }
  }

  // Навигация к экрану создания рецепта
  Future<void> _navigateToCreateRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRecipeScreen(userId: widget.userId),
      ),
    );

    // Если рецепт был создан, обновляем список блюд
    if (result == true) {
      _loadDishes(isInitial: true);
    }
  }

  // Виджет карточки продукта - оптимизированная версия
  Widget _buildProductCard(Product product, {bool isRecent = false}) {
    return RepaintBoundary(
      key: ValueKey(product.id), // Уникальный ключ для оптимизации
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isRecent ? 4 : 8,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRecent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Недавний',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                product.formattedNutrition,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xDD000000), // const вместо Colors.black87
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Порция: ${product.formattedServingNutrition}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E), // const вместо Colors.grey
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: const Icon(
            Icons.add_circle_outline,
            color: Colors.green,
            size: 28,
          ),
          onTap: () => _onProductSelected(product),
        ),
      ),
    );
  }

  // Виджет карточки блюда - оптимизированная версия
  Widget _buildDishCard(Dish dish, {bool isRecent = false}) {
    return RepaintBoundary(
      key: ValueKey(dish.id), // Уникальный ключ для оптимизации
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isRecent ? 4 : 8,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  dish.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRecent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Недавний',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                dish.formattedNutrition,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xDD000000), // const вместо Colors.black87
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                dish.ingredientsCount,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E), // const вместо Colors.grey
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: const Icon(
            Icons.add_circle_outline,
            color: Colors.green,
            size: 28,
          ),
          onTap: () => _onDishSelected(dish),
        ),
      ),
    );
  }

  // Виджет списка продуктов
  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorProducts != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки продуктов',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_errorProducts!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadProducts(isInitial: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Комбинируем недавние и обычные продукты
    final allProducts = <Product>[];
    final recentProductsToShow = _currentSearchQuery.isEmpty ? _recentProducts : <Product>[];
    
    allProducts.addAll(recentProductsToShow);
    allProducts.addAll(_products.where((p) => !recentProductsToShow.any((r) => r.id == p.id)));

    if (allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fastfood, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _currentSearchQuery.isEmpty ? 'Нет продуктов' : 'Продукты не найдены',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentSearchQuery.isEmpty 
                  ? 'Создайте первый продукт'
                  : 'Попробуйте изменить поисковый запрос',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Кнопка создания продукта в пустом состоянии
            if (_currentSearchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _navigateToCreateProduct,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Создать продукт',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Кнопка создания продукта
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateProduct,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Создать продукт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        
        // Список продуктов
        Expanded(
          child: ListView.builder(
            controller: _productsScrollController,
            itemCount: allProducts.length + (_isLoadingMoreProducts ? 1 : 0),
            physics: const AlwaysScrollableScrollPhysics(), // Оптимизация прокрутки
            cacheExtent: 200, // Кэшируем элементы на 200 пикселей вперед
            itemBuilder: (context, index) {
              if (index >= allProducts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final product = allProducts[index];
              final isRecent = recentProductsToShow.contains(product);
              
              return _buildProductCard(product, isRecent: isRecent);
            },
          ),
        ),
      ],
    );
  }

  // Виджет списка блюд
  Widget _buildDishesList() {
    if (_isLoadingDishes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorDishes != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки блюд',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_errorDishes!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDishes(isInitial: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Комбинируем недавние и обычные блюда
    final allDishes = <Dish>[];
    final recentDishesToShow = _currentSearchQuery.isEmpty ? _recentDishes : <Dish>[];
    
    allDishes.addAll(recentDishesToShow);
    allDishes.addAll(_dishes.where((d) => !recentDishesToShow.any((r) => r.id == d.id)));

    if (allDishes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _currentSearchQuery.isEmpty ? 'Нет блюд' : 'Блюда не найдены',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentSearchQuery.isEmpty 
                  ? 'Создайте первое блюдо'
                  : 'Попробуйте изменить поисковый запрос',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Кнопка создания рецепта в пустом состоянии
            if (_currentSearchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: _navigateToCreateRecipe,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Создать рецепт',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Кнопка создания рецепта
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateRecipe,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Создать рецепт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        
        // Список блюд
        Expanded(
          child: ListView.builder(
            controller: _dishesScrollController,
            itemCount: allDishes.length + (_isLoadingMoreDishes ? 1 : 0),
            physics: const AlwaysScrollableScrollPhysics(), // Оптимизация прокрутки
            cacheExtent: 200, // Кэшируем элементы на 200 пикселей вперед
            itemBuilder: (context, index) {
              if (index >= allDishes.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final dish = allDishes[index];
              final isRecent = recentDishesToShow.contains(dish);
              
              return _buildDishCard(dish, isRecent: isRecent);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор продуктов и блюд'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Поисковая строка
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Поиск продуктов и блюд...',
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    filled: true,
                    fillColor: Colors.white24,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              
              // Вкладки
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.fastfood),
                    text: 'Продукты',
                  ),
                  Tab(
                    icon: Icon(Icons.restaurant),
                    text: 'Блюда',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsList(),
          _buildDishesList(),
        ],
      ),
    );
  }
} 