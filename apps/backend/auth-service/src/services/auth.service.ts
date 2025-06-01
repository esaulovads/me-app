import { v4 as uuidv4 } from 'uuid';
import { User, IUser } from '../models/user.model';

export class AuthService {
  /**
   * Проверяет существование пользователя и возвращает его данные или создает нового
   * @param deviceId - Уникальный идентификатор устройства
   */
  async authenticateUser(deviceId: string): Promise<IUser> {
    try {
      // Ищем пользователя по deviceId (который используется как userId)
      let user = await User.findOne({ userId: deviceId });

      // Если пользователь не найден, создаем нового
      if (!user) {
        user = await User.create({
          userId: deviceId,
          createdAt: new Date(),
          lastLoginAt: new Date(),
        });
      } else {
        // Обновляем дату последнего входа
        user.lastLoginAt = new Date();
        await user.save();
      }

      return user;
    } catch (error: any) {
      throw new Error(`Ошибка аутентификации: ${error?.message || 'Неизвестная ошибка'}`);
    }
  }

  /**
   * Получает данные пользователя по ID
   * @param userId - ID пользователя
   */
  async getUserById(userId: string): Promise<IUser | null> {
    try {
      return await User.findOne({ userId });
    } catch (error: any) {
      throw new Error(`Ошибка получения данных пользователя: ${error?.message || 'Неизвестная ошибка'}`);
    }
  }
} 