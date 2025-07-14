import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

/**
 * Сервис питания:
 * - Управление приемами пищи и их КБЖУ
 * - База данных продуктов и рецептов
 * - Расчет текущего потребления КБЖУ и сравнение с нормой
 */

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Включаем валидацию DTO
  app.useGlobalPipes(new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
  }));
  
  // Включаем CORS для фронтенда
  app.enableCors({
    origin: ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true,
  });
  
  // Порт из переменной окружения или 3002 по умолчанию
  const port = process.env.PORT || 3002;
  
  await app.listen(port);
  console.log(`🍽️ Nutrition Service запущен на порту ${port}`);
}

bootstrap().catch((error) => {
  console.error('❌ Ошибка запуска Nutrition Service:', error);
  process.exit(1);
}); 