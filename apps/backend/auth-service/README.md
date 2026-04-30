# Authentication Service for Fitness App

This service is responsible for user authentication and account management in the fitness app.

## Functionality

- Detection of new and existing users
- Creation of new accounts
- Retrieval of existing account data

## Tech Stack

- Node.js
- Express
- TypeScript
- MongoDB
- Mongoose

## Installation and Launch

### Prerequisites

1. Install MongoDB (if not installed yet):
```bash
brew tap mongodb/brew
brew install mongodb-community
```

### Service Startup

1. Start MongoDB:
```bash
brew services start mongodb-community
```

2. Go to the service directory:
```bash
cd apps/backend/auth-service
```

3. Install dependencies (if not installed yet):
```bash
npm install
```

4. Create a `.env` file in the `auth-service` directory and add the following variables:
```
PORT=3000
MONGODB_URI=mongodb://localhost:27017/fitness-app
```

5. Start the service:
```bash
# Development mode
npm run dev

# Production mode
npm run build
npm start
```

### Stopping the Service

1. Stop the service: press `Ctrl + C` in the terminal where the service is running
2. Stop MongoDB:
```bash
brew services stop mongodb-community
```

## Testing with Postman

1. Download and install Postman from the [official website](https://www.postman.com/downloads/)

2. Create a new collection named `Fitness App`

3. Add the following requests:

### User Authentication (`POST /auth`)

- Method: `POST`
- URL: `http://localhost:3000/auth`
- Headers:
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "deviceId": "test-device-123"
}
```

### Get User Data (`GET /users/:userId`)

- Method: `GET`
- URL: `http://localhost:3000/users/test-device-123`
- Headers: not required
- Body: not required

## Expected Responses

### `POST /auth`

Successful response (`200 OK`):
```json
{
  "userId": "test-device-123",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

### `GET /users/:userId`

Successful response (`200 OK`):
```json
{
  "userId": "test-device-123",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

User not found (`404 Not Found`):
```json
{
  "error": "User not found"
}
```

## Common Issues and Solutions

1. **MongoDB connection error**
   - Check that MongoDB is running: `brew services list`
   - Restart MongoDB: `brew services restart mongodb-community`

2. **Service does not start**
   - Check that the `.env` file exists and is valid
   - Ensure all dependencies are installed: `npm install`
   - Check logs for errors

3. **"Connection refused" in Postman**
   - Ensure the service is running on port `3000`
   - Ensure the correct port is used in the URL

## API Endpoints

### `POST /auth`
Authenticates a user or creates a new account.

Request:
```json
{
  "deviceId": "unique-device-identifier"
}
```

Response:
```json
{
  "userId": "unique-device-identifier",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

### `GET /users/:userId`
Returns user data by ID.

Response:
```json
{
  "userId": "unique-device-identifier",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

