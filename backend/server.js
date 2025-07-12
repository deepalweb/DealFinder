const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') }); // Ensure dotenv is loading the .env file from the correct path
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
// Set a more reasonable default body limit. 10MB is still generous.
// If specific routes need larger limits (e.g., for base64 image uploads),
// they can have bodyParser middleware applied with a custom limit.
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ limit: '10mb', extended: true }));

// CORS Configuration
const allowedOrigins_DEV = [
  'http://127.0.0.1:5001',
  'http://localhost:5001',
  'http://127.0.0.1:5500', // VS Code Live Server
  // Include Azure URL if it's used for development/staging branches accessible during dev
  'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net'
];
const allowedOrigins_PROD = [
  'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net',
  'https://drstores.lk'
  // Add any other production frontend domains here
];
const currentOrigins = process.env.NODE_ENV === 'production' ? allowedOrigins_PROD : allowedOrigins_DEV;

console.log(`CORS enabled for NODE_ENV: ${process.env.NODE_ENV || 'development (default)'}`);
console.log('Allowed CORS origins:', currentOrigins);

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps, curl, server-to-server)
    if (!origin) return callback(null, true);

    if (currentOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.warn(`CORS: Blocked origin - ${origin}`);
      callback(new Error(`CORS policy does not allow access from origin: ${origin}`), false);
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true,
}));


// API status route
app.get('/api/status', (req, res) => {
  res.send('API is running...');
});

// Import Routes
const userRoutes = require('./routes/userRoutes');
const promotionRoutes = require('./routes/promotionRoutes');
const merchantRoutes = require('./routes/merchantRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const googleMapsRoutes = require('./routes/googleMapsRoutes'); // Import the new routes
const adminPromotionRoutes = require('./routes/adminRoutes/adminPromotionRoutes');
const adminDashboardRoutes = require('./routes/adminRoutes/adminDashboardRoutes');

// Use API Routes
app.use('/api/users', userRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/maps', googleMapsRoutes); // Use the new maps routes
app.use('/api/merchants', merchantRoutes);
app.use('/api/notifications', notificationRoutes);

// Group admin routes under /api/admin
const adminRouter = express.Router();
adminRouter.use('/', adminPromotionRoutes); // Mounted at /api/admin/promotions (due to internal routing)
adminRouter.use('/', adminDashboardRoutes); // Mounted at /api/admin/dashboard/stats (due to internal routing)
app.use('/api/admin', adminRouter);

// Serve static files - IMPORTANT: These must come BEFORE the catch-all routes
app.use('/backend/public/libs', express.static(path.join(__dirname, 'public/libs')));
app.use('/scripts', express.static(path.join(__dirname, '../frontend/scripts')));
app.use('/styles', express.static(path.join(__dirname, '../frontend/styles')));

// Debug route to test static file serving
app.get('/test-static', (req, res) => {
  res.send('Static file serving is working');
});

// Connect to MongoDB with better error handling
mongoose.connect(process.env.MONGO_URI)
.then(() => console.log('Connected to MongoDB'))
.catch((err) => {
  console.error('Error connecting to MongoDB:', err);
  // Log more details about the connection attempt
  console.error('MongoDB URI (masked):', process.env.MONGO_URI ? '***' + process.env.MONGO_URI.substring(process.env.MONGO_URI.indexOf('@')) : 'Not provided');
  console.error('Environment:', process.env.NODE_ENV);
});

// Serve the frontend at the root URL - This should come AFTER all API and static routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// Fallback route for SPA - This should be the LAST route
app.get('*', (req, res) => {
  // Exclude .js files from the catch-all route to prevent serving HTML for JS requests
  if (req.path.endsWith('.js') || req.path.endsWith('.css') || req.path.endsWith('.png') || req.path.endsWith('.jpg') || req.path.endsWith('.svg')) {
    return res.status(404).send('File not found');
  }
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// Global error handling middleware
app.use((err, req, res, next) => {
  console.error('API Error:', err);
  res.status(500).json({ 
    message: 'Internal Server Error', 
    error: process.env.NODE_ENV === 'production' ? 'An error occurred' : err.message 
  });
});

// Ensure JWT_SECRET is set
if (!process.env.JWT_SECRET) {
  console.warn('Warning: JWT_SECRET is not set in environment variables. Using default (insecure) secret.');
  console.warn('To fix: Set JWT_SECRET in a .env file at backend/.env or in your environment variables.');
}

// Ensure JWT_REFRESH_SECRET is set
if (!process.env.JWT_REFRESH_SECRET) {
  console.warn('Warning: JWT_REFRESH_SECRET is not set in environment variables. Using default (insecure) secret.');
  console.warn('To fix: Set JWT_REFRESH_SECRET in a .env file at backend/.env or in your environment variables.');
}

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = mongoose;
