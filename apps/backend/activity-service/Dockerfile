FROM node:18-alpine

WORKDIR /app

# Копируем файлы package.json и package-lock.json
COPY package*.json ./

# Устанавливаем зависимости
RUN npm ci --only=production

# Копируем исходный код
COPY . .

# Собираем приложение
RUN npm run build

# Экспонируем порт
EXPOSE 3004

# Запускаем приложение
CMD ["npm", "run", "start"]
