const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Merchant = require('../models/Merchant');

// Get all users
router.get('/', async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching users', error });
  }
});

// Get a user by ID
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json(user);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching user', error });
  }
});

// Register a new user
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, businessName } = req.body;
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }
    
    // Create user
    const user = new User({
      name,
      email,
      password, // In a real app, you would hash this password
      role: role || 'user',
      businessName
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
    
    res.status(201).json(userResponse);
  } catch (error) {
    res.status(500).json({ message: 'Error registering user', error });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // Check password (in a real app, you would compare hashed passwords)
    if (user.password !== password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    // Don't return the password
    const userResponse = user.toObject();
    delete userResponse.password;
    
    res.status(200).json(userResponse);
  } catch (error) {
    res.status(500).json({ message: 'Error logging in', error });
  }
});

// Update user profile
router.put('/:id', async (req, res) => {
  try {
    const { name, email, businessName } = req.body;
    
    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, businessName },
      { new: true }
    ).select('-password');
    
    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // If user is a merchant, update merchant name too
    if (updatedUser.role === 'merchant' && updatedUser.merchantId) {
      await Merchant.findByIdAndUpdate(
        updatedUser.merchantId,
        { name: businessName || updatedUser.name }
      );
    }
    
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(500).json({ message: 'Error updating user', error });
  }
});

// Add promotion to favorites
router.post('/:id/favorites', async (req, res) => {
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
    res.status(500).json({ message: 'Error adding to favorites', error });
  }
});

// Remove promotion from favorites
router.delete('/:id/favorites/:promotionId', async (req, res) => {
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
    res.status(500).json({ message: 'Error removing from favorites', error });
  }
});

// Get user's favorite promotions
router.get('/:id/favorites', async (req, res) => {
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
    res.status(500).json({ message: 'Error fetching favorites', error });
  }
});

module.exports = router;