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
const { ensureFirebaseAdminInitialized } = require('./services/firebaseAdmin');
const { ensurePostgresConnected } = require('./services/postgres');

// Refuse to start without signing secrets: a default would let anyone forge tokens.
for (const key of ['JWT_SECRET', 'JWT_REFRESH_SECRET']) {
  if (!process.env[key]) {
    throw new Error(`${key} must be set (backend/.env or environment).`);
  }
}

const app = express();
const PORT = process.env.PORT || 8080;
const APP_URL =
  process.env.APP_URL || 'https://dealfinderapp.lk';

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
  'https://www.dealfinderapp.lk',
  'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net'
];
const currentOrigins = process.env.NODE_ENV === 'production' ? allowedOrigins_PROD : allowedOrigins_DEV;

console.log(`CORS enabled for NODE_ENV: ${process.env.NODE_ENV || 'development (default)'}`);
console.log('Allowed CORS origins:', currentOrigins);

app.use(cors({
  origin: function (origin, callback) {
    if (!origin) return callback(null, true);
    const isDevLocalhost = process.env.NODE_ENV !== 'production' &&
      /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
    if (currentOrigins.indexOf(origin) !== -1 || isDevLocalhost) {
      callback(null, true);
    } else {
      console.warn(`CORS: Blocked origin - ${origin}`);
      callback(null, false);
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
const bankOfferRoutes = require('./routes/bankOfferRoutes');
const merchantRoutes = require('./routes/merchantRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminPromotionRoutes = require('./routes/adminRoutes/adminPromotionRoutes');
const adminDashboardRoutes = require('./routes/adminRoutes/adminDashboardRoutes');
const adminSectionRoutes = require('./routes/adminRoutes/adminSectionRoutes');
const adminReportRoutes = require('./routes/adminRoutes/adminReportRoutes');
const imageRoutes = require('./routes/imageRoutes');
const aiRoutes = require('./routes/aiRoutes');

// Use API Routes
app.use('/api/users/login', loginLimiter);
app.use('/api/users/register', registerLimiter);
app.use('/api', apiLimiter);
app.use('/api/users', userRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/bank-offers', bankOfferRoutes);
app.use('/api/merchants', merchantRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/images', imageRoutes);
app.use('/api/ai', aiRoutes);

// Group admin routes under /api/admin
const adminRouter = express.Router();
adminRouter.use('/', adminPromotionRoutes); // Mounted at /api/admin/promotions (due to internal routing)
adminRouter.use('/', adminDashboardRoutes); // Mounted at /api/admin/dashboard/stats (due to internal routing)
adminRouter.use('/', adminSectionRoutes);
adminRouter.use('/', adminReportRoutes);
app.use('/api/admin', adminRouter);

// Serve static files - IMPORTANT: These must come BEFORE the catch-all routes
app.use('/backend/public/libs', express.static(path.join(__dirname, 'public/libs')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Debug route to test static file serving
app.get('/test-static', (req, res) => {
  res.send('Static file serving is working');
});

// Connect to MongoDB with optimized settings for Azure Cosmos DB.
// Skipped entirely when running on Postgres (DATA_SOURCE=postgres) — there is
// no Mongo instance to connect to, and every route branches away from Mongoose
// in that mode, so attempting this connection only produces a startup error.
if (process.env.DATA_SOURCE !== 'postgres') {
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
} else {
  console.log('DATA_SOURCE=postgres — skipping MongoDB connection.');
}

// Connect to Postgres (Supabase) - separate from MongoDB, does not block app startup
ensurePostgresConnected();

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
  // Development: the web app is frontend-next, run separately (npm run dev on
  // port 3000) rather than served through this backend. The old static
  // `frontend/` directory this used to serve no longer exists in the repo.
  app.get('/', (_req, res) => {
    res.status(200).send('DealFinder API is running. The web app runs separately — see frontend-next (npm run dev, http://localhost:3000).');
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

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  ensureFirebaseAdminInitialized();

  // Notification jobs (nearby deals, expiry, price drops, etc.) all query Mongoose
  // models directly and haven't been ported to Postgres yet — skip registering them
  // in that mode rather than let each one fail on its schedule.
  if (process.env.DATA_SOURCE !== 'postgres') {
    initializeNotificationJobs();

    // Legacy: Run expiry notifications daily at startup then every 24 hours
    // (This is now handled by the job scheduler, but keeping for backward compatibility)
    sendExpiryNotifications();
    setInterval(sendExpiryNotifications, 24 * 60 * 60 * 1000);
  } else {
    console.log('DATA_SOURCE=postgres — skipping Mongo-only notification jobs.');
  }
});

// Setup web-push
if (config.VAPID_PUBLIC_KEY && config.VAPID_PRIVATE_KEY) {
    webpush.setVapidDetails(
        `mailto:${process.env.CONTACT_EMAIL || 'admin@dealfinderapp.lk'}`,
        config.VAPID_PUBLIC_KEY,
        config.VAPID_PRIVATE_KEY
    );
    console.log('Web Push VAPID details set.');
} else {
    console.warn('VAPID keys not found. Push notifications will not work.');
}

module.exports = mongoose;
