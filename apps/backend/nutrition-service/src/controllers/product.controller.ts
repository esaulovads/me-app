import { Controller, Get, Post, Put, Delete, Body, Param, Headers, NotFoundException, Query } from '@nestjs/common';
import { ProductService } from '../services/product.service';
import { CreateProductDto } from '../dto/create-product.dto';
import { Product } from '../entities/product.entity';

@Controller('products')
export class ProductController {
  constructor(private readonly productService: ProductService) {}

  @Post()
  async create(
    @Headers('user-id') userId: string,
    @Body() createProductDto: CreateProductDto,
  ): Promise<Product> {
    return this.productService.create(userId, createProductDto);
  }

  @Get()
  async findAll(
    @Headers('user-id') userId: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('search') search?: string,
  ): Promise<{ products: Product[]; total: number }> {
    const limitNum = limit ? parseInt(limit, 10) : 10;
    const offsetNum = offset ? parseInt(offset, 10) : 0;
    return this.productService.findAllByUserId(userId, limitNum, offsetNum, search);
  }

  @Get('recent')
  async getRecentProducts(@Headers('user-id') userId: string): Promise<Product[]> {
    return this.productService.getRecentProducts(userId);
  }

  @Get(':id')
  async findOne(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ): Promise<Product> {
    const product = await this.productService.findOne(id, userId);
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return product;
  }

  @Put(':id')
  async update(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
    @Body() updateProductDto: Partial<CreateProductDto>,
  ): Promise<Product> {
    const product = await this.productService.update(id, userId, updateProductDto);
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return product;
  }

  @Delete(':id')
  async delete(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ): Promise<void> {
    return this.productService.delete(id, userId);
  }
} 