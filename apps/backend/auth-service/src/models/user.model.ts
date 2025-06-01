import mongoose, { Schema, Document } from 'mongoose';

// Интерфейс для типизации модели пользователя
export interface IUser extends Document {
  userId: string;           // Уникальный идентификатор пользователя
  createdAt: Date;         // Дата создания аккаунта
  lastLoginAt: Date;       // Дата последнего входа
  // Поля, которые будут добавлены позже:
  name?: string;           // Имя пользователя (опционально)
  height?: number;         // Рост в см (опционально)
  weight?: number;         // Вес в кг (опционально)
  dailyCalories?: number;  // Дневная норма калорий (опционально)
}

// Схема пользователя
const UserSchema: Schema = new Schema({
  userId: {
    type: String,
    required: true,
    unique: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  lastLoginAt: {
    type: Date,
    default: Date.now,
  },
  name: {
    type: String,
    required: false,
  },
  height: {
    type: Number,
    required: false,
  },
  weight: {
    type: Number,
    required: false,
  },
  dailyCalories: {
    type: Number,
    required: false,
  },
});

// Создаем и экспортируем модель
export const User = mongoose.model<IUser>('User', UserSchema); 