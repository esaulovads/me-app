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
      const { deviceId } = req.body;

      if (!deviceId) {
        res.status(400).json({ error: 'DeviceId обязателен' });
        return;
      }

      const user = await this.authService.authenticateUser(deviceId);
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
      const { userId } = req.params;

      if (!userId) {
        res.status(400).json({ error: 'UserId обязателен' });
        return;
      }

      const user = await this.authService.getUserById(userId);
      
      if (!user) {
        res.status(404).json({ error: 'Пользователь не найден' });
        return;
      }

      res.status(200).json(user);
    } catch (error) {
      console.error('Ошибка получения данных пользователя:', error);
      res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
  };
} 