import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { Product } from '../entities/product.entity';
import { CreateProductDto } from '../dto/create-product.dto';

@Injectable()
export class ProductService {
  constructor(
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
  ) {}

  async create(userId: string, createProductDto: CreateProductDto): Promise<Product> {
    const product = this.productRepository.create({
      userId,
      ...createProductDto,
      // Рассчитываем КБЖУ для порции
      caloriesPerServing: (createProductDto.caloriesPer100g / 100) * createProductDto.servingWeight,
      proteinsPerServing: (createProductDto.proteinsPer100g / 100) * createProductDto.servingWeight,
      fatsPerServing: (createProductDto.fatsPer100g / 100) * createProductDto.servingWeight,
      carbsPerServing: (createProductDto.carbsPer100g / 100) * createProductDto.servingWeight,
    });

    return this.productRepository.save(product);
  }

  async findAllByUserId(
    userId: string,
    limit: number = 10,
    offset: number = 0,
    search?: string,
  ): Promise<{ products: Product[]; total: number }> {
    const where: any = { userId };
    
    // Добавляем поиск по названию, если задан
    if (search) {
      where.name = Like(`%${search}%`);
    }

    const [products, total] = await this.productRepository.findAndCount({
      where,
      order: { name: 'ASC' },
      take: limit,
      skip: offset,
    });

    return { products, total };
  }

  // Получение недавно использованных продуктов пользователя
  async getRecentProducts(userId: string): Promise<Product[]> {
    // Получаем уникальные продукты из недавних приемов пищи (за последние 30 дней)
    const query = `
      SELECT DISTINCT p.*
      FROM products p
      INNER JOIN meal_items mi ON p.id = mi."productId"
      INNER JOIN meals m ON mi."mealId" = m.id
      WHERE m."userId" = $1 
        AND mi.type = 'PRODUCT'
        AND m."createdAt" >= NOW() - INTERVAL '30 days'
      ORDER BY MAX(m."createdAt") DESC
      LIMIT 10
    `;

    return this.productRepository.query(query, [userId]);
  }

  async findOne(id: string, userId: string): Promise<Product> {
    return this.productRepository.findOne({
      where: { id, userId },
    });
  }

  async update(id: string, userId: string, updateData: Partial<CreateProductDto>): Promise<Product> {
    const product = await this.findOne(id, userId);
    if (!product) {
      return null;
    }

    // Обновляем базовые поля
    Object.assign(product, updateData);

    // Если изменились базовые значения КБЖУ или вес порции, пересчитываем значения для порции
    if (updateData.caloriesPer100g || updateData.servingWeight) {
      product.caloriesPerServing = (product.caloriesPer100g / 100) * product.servingWeight;
    }
    if (updateData.proteinsPer100g || updateData.servingWeight) {
      product.proteinsPerServing = (product.proteinsPer100g / 100) * product.servingWeight;
    }
    if (updateData.fatsPer100g || updateData.servingWeight) {
      product.fatsPerServing = (product.fatsPer100g / 100) * product.servingWeight;
    }
    if (updateData.carbsPer100g || updateData.servingWeight) {
      product.carbsPerServing = (product.carbsPer100g / 100) * product.servingWeight;
    }

    return this.productRepository.save(product);
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.productRepository.delete({ id, userId });
  }
} 