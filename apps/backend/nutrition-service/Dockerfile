# Этап сборки
FROM node:20-alpine as builder

WORKDIR /app

# Копируем package.json и package-lock.json
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем исходный код и конфигурационные файлы
COPY tsconfig.json .
COPY src ./src

# Устанавливаем TypeScript глобально
RUN npm install -g typescript

# Проверяем структуру проекта
RUN ls -la

# Собираем приложение
RUN npm run build

# Проверяем результат сборки
RUN ls -la dist

# Этап production
FROM node:20-alpine

WORKDIR /app

# Копируем собранное приложение и зависимости
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./

# Создаем пользователя для запуска приложения
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

# Меняем владельца файлов
RUN chown -R nestjs:nodejs /app

USER nestjs

# Указываем порт (будет переопределен через .env)
EXPOSE 3002

# Проверяем структуру перед запуском
RUN ls -la dist

CMD ["node", "dist/main.js"] 