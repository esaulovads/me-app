import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import dotenv from 'dotenv';
import { AuthController } from './controllers/auth.controller';

// Загружаем переменные окружения
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/fitness-app';

// Middleware
app.use(cors());
app.use(express.json());

// Инициализируем контроллер
const authController = new AuthController();

// Маршруты
app.post('/auth', authController.authenticate);
app.get('/users/:userId', authController.getUser);

// Подключение к MongoDB
mongoose.connect(mongoUri)
  .then(() => {
    console.log('Подключено к MongoDB');
    
    // Запускаем сервер только после успешного подключения к БД
    app.listen(port, () => {
      console.log(`Сервер запущен на порту ${port}`);
    });
  })
  .catch((error) => {
    console.error('Ошибка подключения к MongoDB:', error);
    process.exit(1);
  }); 