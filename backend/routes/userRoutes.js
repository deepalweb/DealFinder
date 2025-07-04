const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');
const { authenticateJWT, authorizeAdmin, authorizeSelfOrAdmin } = require('../middleware/auth');

// In-memory store for refresh tokens
const refreshTokens = new Set();

// Helper: Generate JWT
function generateToken(user) {
  return jwt.sign(
    // Ensure merchantId is included in the token if the user is a merchant
    { id: user._id, email: user.email, role: user.role, merchantId: user.merchantId },
    process.env.JWT_SECRET || 'your_jwt_secret',
    { expiresIn: '7d' }
  );
}

// Helper: Generate Refresh Token
function generateRefreshToken(user) {
  return jwt.sign(
    // Ensure merchantId is included in the token if the user is a merchant
    { id: user._id, email: user.email, role: user.role, merchantId: user.merchantId },
    process.env.JWT_REFRESH_SECRET || 'your_jwt_refresh_secret',
    { expiresIn: '30d' }
  );
}

// Middleware to protect routes
function protectRoute(req, res, next) {
  const openRoutes = [
    { path: '/register', method: 'POST' },
    { path: '/login', method: 'POST' },
    { path: '/refresh-token', method: 'POST' },
    { path: '/reset-password', method: 'POST' },
    { path: '/reset-password/confirm', method: 'POST' }
  ];

  if (openRoutes.some(r => r.path === req.path && r.method === req.method)) {
    return next();
  }
  authenticateJWT(req, res, next);
}

router.use(protectRoute);

// Get all users (Admin only)
// Uses authorizeAdmin imported from ../middleware/auth
router.get('/', authorizeAdmin, async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get a user by ID (Self or Admin)
router.get('/:id', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Register a new user
router.post('/register', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('role').optional().isIn(['user', 'merchant']).withMessage('Role must be user or merchant'),
  body('businessName').optional().isString(),
  body('profilePicture').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, email, password, role, businessName, profilePicture } = req.body;
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }
    
    // Hash password before saving
    const hashedPassword = await bcrypt.hash(password, 10);
    // Create user
    const user = new User({
      name,
      email,
      password: hashedPassword,
      role: role || 'user',
      businessName,
      profilePicture
    });
    
    const savedUser = await user.save();
    
    // If registering as a merchant, create a merchant profile
    if (role === 'merchant' && businessName) {
      const merchant = new Merchant({
        name: businessName,
        contactInfo: email
      });
      
      const savedMerchant = await merchant.save();
      
      // Link merchant to user
      savedUser.merchantId = savedMerchant._id;
      await savedUser.save();
    }
    
    // Don't return the password
    const userResponse = savedUser.toObject();
    delete userResponse.password;
    // Generate tokens
    const token = generateToken(savedUser);
    const refreshToken = generateRefreshToken(savedUser);
    refreshTokens.add(refreshToken);
    res.status(201).json({ ...userResponse, token, refreshToken });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Login user
router.post('/login', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { email, password } = req.body;
    
    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // Check password using bcrypt
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // Don't return the password
    const userResponse = user.toObject();
    delete userResponse.password;
    // Generate tokens
    const token = generateToken(user);
    const refreshToken = generateRefreshToken(user);
    refreshTokens.add(refreshToken);
    res.status(200).json({ ...userResponse, token, refreshToken });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Refresh token endpoint
router.post('/refresh-token', (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken || !refreshTokens.has(refreshToken)) {
    return res.status(401).json({ message: 'Invalid refresh token' });
  }
  jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || 'your_jwt_refresh_secret', (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid or expired refresh token' });
    const newToken = generateToken(user);
    res.status(200).json({ token: newToken });
  });
});

// Logout (invalidate refresh token)
router.post('/logout', (req, res) => {
  const { refreshToken } = req.body;
  if (refreshToken) refreshTokens.delete(refreshToken);
  res.status(200).json({ message: 'Logged out successfully' });
});

// Update user profile (Self or Admin)
router.put('/:id', authorizeSelfOrAdmin, [
  body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
  body('email').optional().isEmail().withMessage('Valid email is required'),
  body('businessName').optional().isString(),
  body('logo').optional().isString(),
  body('profilePicture').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, email, businessName, logo, profilePicture } = req.body;
    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, businessName, logo, profilePicture },
      { new: true }
    ).select('-password');
    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    // If user is a merchant, update merchant name and logo too
    if (updatedUser.role === 'merchant' && updatedUser.merchantId) {
      await Merchant.findByIdAndUpdate(
        updatedUser.merchantId,
        { name: businessName || updatedUser.name, logo }
      );
    }
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Add promotion to favorites (Self or Admin)
router.post('/:id/favorites', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const { promotionId } = req.body;
    
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if promotion is already in favorites
    if (user.favorites.includes(promotionId)) {
      return res.status(400).json({ message: 'Promotion already in favorites' });
    }
    
    user.favorites.push(promotionId);
    await user.save();
    
    res.status(200).json({ message: 'Added to favorites', favorites: user.favorites });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Remove promotion from favorites (Self or Admin)
router.delete('/:id/favorites/:promotionId', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    user.favorites = user.favorites.filter(
      fav => fav.toString() !== req.params.promotionId
    );
    
    await user.save();
    
    res.status(200).json({ message: 'Removed from favorites', favorites: user.favorites });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get user's favorite promotions (Self or Admin)
router.get('/:id/favorites', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).populate({
      path: 'favorites',
      populate: { path: 'merchant' }
    });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.status(200).json(user.favorites);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Password reset request (step 1)
router.post('/reset-password', async (req, res) => {
  const { email } = req.body;
  if (!email || !/\S+@\S+\.\S+/.test(email)) {
    return res.status(400).json({ message: 'Please provide a valid email address.' });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) {
      // Respond with success even if user not found (to prevent email enumeration)
      return res.status(200).json({ message: 'If your email is registered, you will receive a password reset link.' });
    }
    // Generate a secure random token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetPasswordExpires = Date.now() + 60 * 60 * 1000; // 1 hour
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = resetPasswordExpires;
    await user.save();
    // In a real app, send an email with the reset link
    console.log(`Password reset link for ${email}: http://localhost:5001/reset-password?token=${resetToken}`);
    return res.status(200).json({ message: 'If your email is registered, you will receive a password reset link.' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Password reset confirmation (step 2)
router.post('/reset-password/confirm', async (req, res) => {
  const { token, password } = req.body;
  if (!token || !password) {
    return res.status(400).json({ message: 'Token and new password are required.' });
  }
  try {
    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });
    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired token.' });
    }
    // Hash new password
    const hashedPassword = await bcrypt.hash(password, 10);
    user.password = hashedPassword;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();
    res.status(200).json({ message: 'Password has been reset successfully.' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Remove sensitive error details from all API responses in production
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// Example: Protect a route (uncomment and use as needed)
// router.get('/protected', authenticateJWT, (req, res) => {
//   res.json({ message: 'This is a protected route', user: req.user });
// });

module.exports = router;