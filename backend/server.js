const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') }); // Ensure dotenv is loading the .env file from the correct path
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 5001;

// Middleware
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));


// Ensure CORS is properly configured
app.use(cors({
  origin: ['http://127.0.0.1:5500', 'http://localhost:5500'], // Allow Live Server origin (adjust port if needed)
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true,
}));

// Serve static files from backend/public/libs under /backend/public/libs path
app.use('/backend/public/libs', express.static(path.join(__dirname, 'public/libs')));

// Serve static files (scripts, styles) from the frontend directory
app.use('/scripts', express.static(path.join(__dirname, '../frontend/scripts')));
app.use('/styles', express.static(path.join(__dirname, '../frontend/styles')));

// Remove the overly broad static serving of the parent directory
// app.use(express.static(path.join(__dirname, '../')));

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('Connected to MongoDB'))
  .catch((err) => console.error('Error connecting to MongoDB:', err));

// Import Routes
const userRoutes = require('./routes/userRoutes');
const promotionRoutes = require('./routes/promotionRoutes');
const merchantRoutes = require('./routes/merchantRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

// Use Routes
app.use('/api/users', userRoutes);
app.use('/api/promotions', promotionRoutes);
app.use('/api/merchants', merchantRoutes);
app.use('/api/notifications', notificationRoutes);

// API status route
app.get('/api/status', (req, res) => {
  res.send('API is running...');
});

// Serve the frontend at the root URL
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// Fallback route for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html')); // Point to the frontend index.html
});

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = mongoose;