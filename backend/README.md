# WiseRide Backend API

Backend API for WiseRide - Public Transport Scheduling and Route Guidance App for Addis Ababa

## Features

- User authentication (registration, login, profile management)
- Ride management (create, track, update status)
- School transport contracts
- Real-time transport updates
- Route optimization
- Health-conscious routing options

## Tech Stack

- Node.js
- Express.js
- MongoDB with Mongoose
- JWT for authentication
- bcryptjs for password hashing

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or cloud instance)

### Installation

1. Clone the repository
2. Navigate to the backend directory:
   ```
   cd backend
   ```
3. Install dependencies:
   ```
   npm install
   ```
4. Create a `.env` file based on `.env.example`:
   ```
   cp .env.example .env
   ```
5. Update the `.env` file with your configuration:
   ```
   NODE_ENV=development
   PORT=5000
   MONGO_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret_key
   ```

### Running the Application

#### Development Mode
```
npm run dev
```

#### Production Mode
```
npm start
```

## API Endpoints

### Authentication
- `POST /api/users/register` - Register a new user
- `POST /api/users/login` - Login user

### User Management
- `GET /api/users/me` - Get current user profile
- `PUT /api/users/me` - Update current user profile
- `GET /api/users` - Get all users (admin)
- `GET /api/users/:id` - Get user by ID

### Ride Management
- `POST /api/rides` - Create a new ride
- `GET /api/rides` - Get user rides
- `GET /api/rides/:id` - Get ride by ID
- `PUT /api/rides/:id` - Update ride status
- `PUT /api/rides/:id/accept` - Accept a ride (drivers)
- `GET /api/rides/available` - Get available rides (drivers)
- `PUT /api/rides/:id/cancel` - Cancel a ride

### School Contracts
- `POST /api/school/contracts` - Create a new contract
- `GET /api/school/contracts` - Get parent contracts
- `GET /api/school/contracts/:id` - Get contract by ID
- `PUT /api/school/contracts/:id` - Update contract
- `PUT /api/school/contracts/:id/status` - Update contract status
- `PUT /api/school/contracts/:id/assign` - Assign driver to contract
- `GET /api/school/contracts/available` - Get available contracts (drivers)

## Project Structure

```
backend/
├── config/          # Database configuration
├── controllers/     # Request handlers
├── middleware/      # Custom middleware
├── models/          # Database models
├── routes/          # API routes
├── .env             # Environment variables
├── .gitignore       # Git ignore file
├── app.js           # Main application file
├── package.json     # Project dependencies
└── README.md        # Project documentation
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| NODE_ENV | Application environment | development |
| PORT | Server port | 5000 |
| MONGO_URI | MongoDB connection string | mongodb://localhost:27017/wiseride |
| JWT_SECRET | Secret key for JWT | wiseride_jwt_secret_key_2025 |

## License

This project is licensed under the MIT License.