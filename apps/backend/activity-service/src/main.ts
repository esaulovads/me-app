import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Включаем валидацию данных
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, // Удаляет свойства, которых нет в DTO
    forbidNonWhitelisted: true, // Выбрасывает ошибку при наличии неразрешенных свойств
    transform: true, // Автоматически преобразует типы данных
  }));

  // Включаем CORS для фронтенда
  app.enableCors();

  const port = process.env.PORT || 3004;
  await app.listen(port);
  console.log(`Activity Service запущен на порту ${port}`);
}

bootstrap();