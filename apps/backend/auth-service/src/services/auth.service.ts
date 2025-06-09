import { v4 as uuidv4 } from 'uuid';
import { User, IUser } from '../models/user.model';

export class AuthService {
  /**
   * Проверяет существование пользователя и возвращает его данные или создает нового
   * @param deviceId - Уникальный идентификатор устройства
   */
  async authenticateUser(deviceId: string): Promise<IUser> {
    try {
      console.log('AuthService: Ищем пользователя с deviceId:', deviceId);
      // Ищем пользователя по deviceId (который используется как userId)
      let user = await User.findOne({ userId: deviceId });

      // Если пользователь не найден, создаем нового
      if (!user) {
        console.log('AuthService: Пользователь не найден, создаем нового');
        user = await User.create({
          userId: deviceId,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        });
        console.log('AuthService: Создан новый пользователь:', user);
      } else {
        console.log('AuthService: Найден существующий пользователь:', user);
        // Обновляем дату последнего входа
        user.lastLoginAt = new Date();
        await user.save();
        console.log('AuthService: Обновлена дата последнего входа:', user);
      }

      return user;
    } catch (error: any) {
      console.error('AuthService: Ошибка аутентификации:', error);
      throw new Error(`Ошибка аутентификации: ${error?.message || 'Неизвестная ошибка'}`);
    }
  }

  /**
   * Получает данные пользователя по ID
   * @param userId - ID пользователя
   */
  async getUserById(userId: string): Promise<IUser | null> {
    try {
      console.log('AuthService: Ищем пользователя по ID:', userId);
      const user = await User.findOne({ userId });
      console.log('AuthService: Результат поиска:', user);
      return user;
    } catch (error: any) {
      console.error('AuthService: Ошибка получения данных пользователя:', error);
      throw new Error(`Ошибка получения данных пользователя: ${error?.message || 'Неизвестная ошибка'}`);
    }
  }
} 