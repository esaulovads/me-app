import 'dart:async';
import 'package:flutter/material.dart';
import '../services/nutrition_service.dart';
import '../models/product_model.dart';
import '../widgets/weight_input_modal.dart';

// Экран выбора продуктов для добавления в рецепт
class ProductPickerScreen extends StatefulWidget {
  final String userId;
  final List<String> excludedProductIds; // Список ID продуктов, которые нужно исключить

  const ProductPickerScreen({
    Key? key,
    required this.userId,
    this.excludedProductIds = const [], // По умолчанию пустой список
  }) : super(key: key);

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  late final NutritionService _nutritionService;
  
  // Контроллеры
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Состояние загрузки и данные
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Данные продуктов
  List<Product> _products = [];
  List<Product> _recentProducts = [];
  int _totalProducts = 0;
  int _currentOffset = 0;
  
  // Поисковый запрос
  String _currentSearchQuery = '';
  Timer? _searchDebounce;
  
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(userId: widget.userId);
    
    // Загружаем начальные данные
    _loadInitialData();
    
    // Настраиваем слушатели
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _nutritionService.dispose();
    super.dispose();
  }

  // Загрузка начальных данных
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProducts(isInitial: true),
      _loadRecentProducts(),
    ]);
  }

  // Загрузка недавних продуктов
  Future<void> _loadRecentProducts() async {
    try {
      final recentProducts = await _nutritionService.getRecentProducts();
      if (mounted) {
        setState(() {
          _recentProducts = recentProducts;
        });
      }
    } catch (e) {
      // Если не удалось загрузить недавние, продолжаем без них
      print('Не удалось загрузить недавние продукты: $e');
    }
  }

  // Загрузка продуктов
  Future<void> _loadProducts({bool isInitial = false, bool isLoadMore = false}) async {
    if (_isLoading || (_isLoadingMore && isLoadMore)) return;

    if (mounted) {
      setState(() {
        if (isInitial) {
          _isLoading = true;
          _error = null;
          _products.clear();
          _currentOffset = 0;
        } else if (isLoadMore) {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final response = await _nutritionService.getProducts(
        limit: _pageSize,
        offset: isLoadMore ? _currentOffset : 0,
        search: _currentSearchQuery.isNotEmpty ? _currentSearchQuery : null,
      );

      if (mounted) {
        setState(() {
          if (isInitial || !isLoadMore) {
            _products = response.products;
            _currentOffset = response.products.length;
          } else {
            _products.addAll(response.products);
            _currentOffset += response.products.length;
          }
          
          _totalProducts = response.total;
          _isLoading = false;
          _isLoadingMore = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _error = e.toString();
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
        _loadProducts(isInitial: true);
      }
    });
  }

  // Обработка прокрутки для пагинации
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (_currentOffset < _totalProducts && !_isLoadingMore) {
        _loadProducts(isLoadMore: true);
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

    // Возвращаем выбранный продукт с весом
    if (mounted) {
      Navigator.pop(context, {
        'product': product,
        'weight': weight,
      });
    }
  }

  // Виджет карточки продукта
  Widget _buildProductCard(Product product, {bool isRecent = false}) {
    return RepaintBoundary(
      key: ValueKey(product.id),
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
                  color: Color(0xDD000000),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Порция: ${product.formattedServingNutrition}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
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

  // Виджет списка продуктов
  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки продуктов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadProducts(isInitial: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    // Комбинируем недавние и обычные продукты, исключая уже выбранные
    final allProducts = <Product>[];
    final recentProductsToShow = _currentSearchQuery.isEmpty 
        ? _recentProducts.where((p) => !widget.excludedProductIds.contains(p.id)).toList()
        : <Product>[];
    
    allProducts.addAll(recentProductsToShow);
    allProducts.addAll(_products.where((p) => 
        !recentProductsToShow.any((r) => r.id == p.id) && 
        !widget.excludedProductIds.contains(p.id)));

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
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: allProducts.length + (_isLoadingMore ? 1 : 0),
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 200,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбрать продукт'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Поисковая строка
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Поиск продуктов...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          
          // Список продуктов
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
    );
  }
} 