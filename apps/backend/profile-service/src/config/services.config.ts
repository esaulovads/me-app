// Конфигурация для подключения к другим сервисам
export const servicesConfig = {
  sleepService: {
    baseUrl: process.env.SLEEP_SERVICE_URL || 'http://me-app-sleep:3003',
  },
  activityService: {
    baseUrl: process.env.ACTIVITY_SERVICE_URL || 'http://me-app-activity:3004',
  },
};
