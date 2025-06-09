import { Request, Response } from 'express';
import { AuthService } from '../services/auth.service';

export class AuthController {
  private authService: AuthService;

  constructor() {
    this.authService = new AuthService();
  }

  /**
   * Обработчик аутентификации пользователя
   */
  authenticate = async (req: Request, res: Response): Promise<void> => {
    try {
      console.log('Получен запрос на аутентификацию:', req.body);
      const { deviceId } = req.body;

      if (!deviceId) {
        console.log('Ошибка: deviceId не предоставлен');
        res.status(400).json({ error: 'DeviceId обязателен' });
        return;
      }

      console.log('Начинаем аутентификацию для deviceId:', deviceId);
      const user = await this.authService.authenticateUser(deviceId);
      console.log('Пользователь аутентифицирован:', user);
      res.status(200).json(user);
    } catch (error) {
      console.error('Ошибка аутентификации:', error);
      res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  };

  /**
   * Получение данных пользователя
   */
  getUser = async (req: Request, res: Response): Promise<void> => {
    try {
      console.log('Получен запрос на получение данных пользователя:', req.params);
      const { userId } = req.params;

      if (!userId) {
        console.log('Ошибка: userId не предоставлен');
        res.status(400).json({ error: 'UserId обязателен' });
        return;
      }

      console.log('Ищем пользователя с ID:', userId);
      const user = await this.authService.getUserById(userId);
      
      if (!user) {
        console.log('Пользователь не найден:', userId);
        res.status(404).json({ error: 'Пользователь не найден' });
        return;
      }

      console.log('Пользователь найден:', user);
      res.status(200).json(user);
    } catch (error) {
      console.error('Ошибка получения данных пользователя:', error);
      res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  };
} 