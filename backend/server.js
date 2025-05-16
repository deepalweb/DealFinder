const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') }); // Ensure dotenv is loading the .env file from the correct path
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// Ensure CORS is properly configured
app.use(cors({
  origin: [
    'http://127.0.0.1:5001', 
    'http://localhost:5001', 
    'http://127.0.0.1:5500', 
    'http://localhost:5500', 
    'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net'
  ], // Allow both server and Live Server origins
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

// Use API Routes
app.use('/api/users', userRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/merchants', merchantRoutes);
app.use('/api/notifications', notificationRoutes);

// Serve static files - IMPORTANT: These must come BEFORE the catch-all routes
app.use('/backend/public/libs', express.static(path.join(__dirname, 'public/libs')));
app.use('/scripts', express.static(path.join(__dirname, '../frontend/scripts')));
app.use('/styles', express.static(path.join(__dirname, '../frontend/styles')));

// Debug route to test static file serving
app.get('/test-static', (req, res) => {
  res.send('Static file serving is working');
});

// Connect to MongoDB with better error handling
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
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
}

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = mongoose;
