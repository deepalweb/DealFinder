require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
const config = require('./config');
const mongoose = require('mongoose');
const webpush = require('web-push');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const sendExpiryNotifications = require('./jobs/expiryNotifications');
const { initializeNotificationJobs } = require('./jobs/notificationScheduler');

const app = express();
const PORT = process.env.PORT || 8080;
const APP_URL =
  process.env.APP_URL || 'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net';

// Enable gzip compression
app.use(compression());

// Rate limiters
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // max 10 login attempts per 15 min per IP
  message: { message: 'Too many login attempts. Please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // max 5 registrations per hour per IP
  message: { message: 'Too many accounts created. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 500, // increased from 200
  message: { message: 'Too many requests. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// CORS Configuration - MUST be before body parser
const allowedOrigins_DEV = [
  'http://127.0.0.1:5001',
  'http://localhost:5001',
  'http://127.0.0.1:5500',
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://localhost:8080',
  'http://127.0.0.1:8080',
  APP_URL
];
const allowedOrigins_PROD = [
  APP_URL,
  'https://drstores.lk'
];
const currentOrigins = process.env.NODE_ENV === 'production' ? allowedOrigins_PROD : allowedOrigins_DEV;

console.log(`CORS enabled for NODE_ENV: ${process.env.NODE_ENV || 'development (default)'}`);
console.log('Allowed CORS origins:', currentOrigins);

app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    if (currentOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.warn(`CORS: Blocked origin - ${origin}`);
      callback(null, true);
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Middleware
app.use(bodyParser.json({ limit: '15mb' }));
app.use(bodyParser.urlencoded({ limit: '15mb', extended: true }));


// API status route
app.get('/api/status', (req, res) => {
  res.send('API is running... deploy 2026-04-22-nearby-refresh');
});

// Config endpoint
app.get('/api/config', (req, res) => {
  res.json({
    GOOGLE_CLIENT_ID: config.GOOGLE_CLIENT_ID,
    VAPID_PUBLIC_KEY: config.VAPID_PUBLIC_KEY
  });
});

// Import Routes
const userRoutes = require('./routes/userRoutes');
const promotionRoutes = require('./routes/promotionRoutes');
const merchantRoutes = require('./routes/merchantRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const googleMapsRoutes = require('./routes/googleMapsRoutes'); // Import the new routes
const adminPromotionRoutes = require('./routes/adminRoutes/adminPromotionRoutes');
const adminDashboardRoutes = require('./routes/adminRoutes/adminDashboardRoutes');
const adminSectionRoutes = require('./routes/adminRoutes/adminSectionRoutes');
const imageRoutes = require('./routes/imageRoutes');

// Use API Routes
app.use('/api/users/login', loginLimiter);
app.use('/api/users/register', registerLimiter);
app.use('/api', apiLimiter);
app.use('/api/users', userRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/maps', googleMapsRoutes); // Use the new maps routes
app.use('/api/merchants', merchantRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/images', imageRoutes);

// Group admin routes under /api/admin
const adminRouter = express.Router();
adminRouter.use('/', adminPromotionRoutes); // Mounted at /api/admin/promotions (due to internal routing)
adminRouter.use('/', adminDashboardRoutes); // Mounted at /api/admin/dashboard/stats (due to internal routing)
adminRouter.use('/', adminSectionRoutes);
app.use('/api/admin', adminRouter);

// Serve static files - IMPORTANT: These must come BEFORE the catch-all routes
app.use('/backend/public/libs', express.static(path.join(__dirname, 'public/libs')));
app.use('/scripts', express.static(path.join(__dirname, '../frontend/scripts')));
app.use('/styles', express.static(path.join(__dirname, '../frontend/styles')));

// Debug route to test static file serving
app.get('/test-static', (req, res) => {
  res.send('Static file serving is working');
});

// Connect to MongoDB with optimized settings for Azure Cosmos DB
mongoose.connect(process.env.MONGO_URI, {
  tls: true,
  retryWrites: false,
  serverSelectionTimeoutMS: 10000, // Reduced from 30s
  socketTimeoutMS: 20000, // Reduced from 45s
  maxPoolSize: 50, // Increased from 20
  minPoolSize: 10, // Increased from 5
  maxIdleTimeMS: 10000, // Reduced from 30s
  connectTimeoutMS: 10000, // Added
  family: 4, // Force IPv4
})
.then(async () => {
  console.log('Connected to MongoDB');
  try {
    await mongoose.connection.collection('merchants').createIndex({ location: '2dsphere' });
    console.log('2dsphere index ensured on merchants.location');
  } catch (err) {
    console.warn('Could not create 2dsphere index:', err.message);
  }
})
.catch((err) => {
  console.error('Error connecting to MongoDB:', err.message);
  console.error('MongoDB URI host:', process.env.MONGO_URI ? process.env.MONGO_URI.substring(process.env.MONGO_URI.indexOf('@') + 1, process.env.MONGO_URI.indexOf('?')) : 'Not provided');
});

// Serve the frontend
if (process.env.NODE_ENV === 'production') {
  const { spawn } = require('child_process');
  const fs = require('fs');
  // standalone output: deploy/frontend-next/server.js
  const nextServerPath = path.join(__dirname, '../frontend-next/server.js');

  if (fs.existsSync(nextServerPath)) {
    const nextProc = spawn('node', [nextServerPath], {
      env: { ...process.env, PORT: '3000', HOSTNAME: '127.0.0.1' },
      stdio: 'inherit'
    });
    nextProc.on('error', err => console.error('Next.js error:', err.message));
    console.log('Next.js standalone starting on port 3000...');

    // Proxy all non-API requests to Next.js
    const proxy = require('http-proxy-middleware').createProxyMiddleware;
    app.use('/', proxy({
      target: 'http://127.0.0.1:3000',
      changeOrigin: false,
      on: { error: (_e, _r, res) => { res.status(502).send('Starting up...'); } }
    }));
  } else {
    console.warn('Next.js not found at:', nextServerPath);
    // Try alternate path for older deploy layouts
    const altPath = path.join(__dirname, '../frontend-next/frontend-next/server.js');
    if (fs.existsSync(altPath)) {
      console.log('Found Next.js at alternate path:', altPath);
      const nextProc = spawn('node', [altPath], {
        env: { ...process.env, PORT: '3000', HOSTNAME: '127.0.0.1' },
        stdio: 'inherit'
      });
      nextProc.on('error', err => console.error('Next.js error:', err.message));
      const proxy = require('http-proxy-middleware').createProxyMiddleware;
      app.use('/', proxy({
        target: 'http://127.0.0.1:3000',
        changeOrigin: false,
        on: { error: (_e, _r, res) => { res.status(502).send('Starting up...'); } }
      }));
    } else {
      app.get('*', (_req, res) => res.send('App starting... paths checked: ' + nextServerPath + ' | ' + altPath));
    }
  }
} else {
  // Development: serve old frontend
  app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
  });
  app.get('*', (req, res) => {
    if (req.path.endsWith('.js') || req.path.endsWith('.css') || req.path.endsWith('.png') || req.path.endsWith('.jpg') || req.path.endsWith('.svg')) {
      return res.status(404).send('File not found');
    }
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
  });
}

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

  // Initialize notification jobs
  initializeNotificationJobs();
  
  // Legacy: Run expiry notifications daily at startup then every 24 hours
  // (This is now handled by the job scheduler, but keeping for backward compatibility)
  sendExpiryNotifications();
  setInterval(sendExpiryNotifications, 24 * 60 * 60 * 1000);
});

// Setup web-push
if (config.VAPID_PUBLIC_KEY && config.VAPID_PRIVATE_KEY) {
    webpush.setVapidDetails(
        `mailto:${process.env.CONTACT_EMAIL || 'admin@dealfinder.com'}`,
        config.VAPID_PUBLIC_KEY,
        config.VAPID_PRIVATE_KEY
    );
    console.log('Web Push VAPID details set.');
} else {
    console.warn('VAPID keys not found. Push notifications will not work.');
}

module.exports = mongoose;
