const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const sessions = require('../services/sessionService');
const { body, validationResult } = require('express-validator');
const { authenticateJWT, authorizeAdmin, authorizeSelfOrAdmin, gentleAuthenticateJWT } = require('../middleware/auth');
const { findUserByEmail: findPostgresUserByEmail } = require('../services/postgresUserService');

function safeError(_error) { return {message:'An error occurred'}; }

function attachMerchantRatingSummary(merchantDoc) {
  if (!merchantDoc) return merchantDoc;
  const merchant = merchantDoc.toObject ? merchantDoc.toObject() : { ...merchantDoc };
  const ratings = Array.isArray(merchant.ratings) ? merchant.ratings : [];
  const ratingValues = ratings
    .map((rating) => Number(rating?.value) || 0)
    .filter((value) => value > 0);

  return {
    ...merchant,
    averageRating: ratingValues.length
      ? Number((ratingValues.reduce((sum, value) => sum + value, 0) / ratingValues.length).toFixed(1))
      : 0,
    ratingsCount: ratingValues.length,
    ratings: undefined,
  };
}

async function ensureMerchantProfileForUser(user, overrides = {}) {
  if (!user || user.role !== 'merchant' || user.merchantId) {
    return user;
  }

  const contactInfo = overrides.contactInfo || user.email;
  const baseName = (
    overrides.businessName ||
    user.businessName ||
    user.name ||
    'Merchant'
  ).trim();

  // Public contact information is not proof of store ownership.
  let merchant = null;

  if (!merchant) {
    let candidateName = baseName;
    let suffix = 2;

    while (await Merchant.findOne({ name: candidateName })) {
      candidateName = `${baseName} ${suffix}`;
      suffix += 1;
    }

    merchant = await Merchant.create({
      name: candidateName,
      status:'pending_approval',
      contactInfo,
      logo: overrides.logo || user.logo || '',
      profile: overrides.profile || '',
      address: overrides.address || '',
      contactNumber: overrides.contactNumber || '',
      socialMedia: overrides.socialMedia || {},
      promotions: [],
    });
  }

  user.merchantId = merchant._id;
  if (!user.businessName || !user.businessName.trim()) {
    user.businessName = merchant.name;
  }
  await user.save();
  return user;
}

// Middleware to protect routes
function protectRoute(req, res, next) {
  if(process.env.DATA_SOURCE==='postgres')return res.status(503).json({message:'Durable account workflows are not supported for the selected database provider.'});
  const openRoutes = [
    { path: '/register', method: 'POST' }, // Will be handled by gentleAuthenticateJWT
    { path: '/login', method: 'POST' },
    { path: '/refresh-token', method: 'POST' },
    { path: '/reset-password', method: 'POST' },
    { path: '/reset-password/confirm', method: 'POST' },
    { path: '/google-signin', method: 'POST' },
    { path: '/firebase-auth', method: 'POST' }
  ];

  if (openRoutes.some(r => r.path === req.path && r.method === req.method)) {
    return next();
  }
  authenticateJWT(req, res, next);
}

router.use(protectRoute);

// Firebase Auth sync — verify Firebase ID token, create/find user, return JWT
const { admin, ensureFirebaseAdminInitialized } = require('../services/firebaseAdmin');
ensureFirebaseAdminInitialized();

router.post('/firebase-auth', async (req, res) => {
  const { idToken, name, role, businessName } = req.body;
  if (!idToken) return res.status(400).json({ message: 'idToken is required' });
  if (!ensureFirebaseAdminInitialized()) {
    return res.status(503).json({ message: 'Firebase authentication is not configured on the server.' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken, true);
    const { email, uid } = decoded;
    if (typeof email !== 'string' || typeof uid !== 'string') return res.status(401).json({ message: 'An email identity is required' });
    const displayName = decoded.name || name || email.split('@')[0];

    let user = await User.findOne({firebaseUid:uid}).select('+firebaseUid');
    if(!user){
      user=await User.findOne({email}).select('+firebaseUid');
      if(user && (decoded.email_verified!==true || (user.firebaseUid && user.firebaseUid!==uid)))
        return res.status(401).json({message:'Verify your email before linking this account.'});
    }
    if (!user) {
      const hashedPassword = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
      user = new User({
        name: displayName,
        firebaseUid: uid,
        email,
        password: hashedPassword,
        role: role === 'merchant' ? 'merchant' : 'user', // never trust a client-supplied admin role
        businessName,
      });
      const savedUser = await user.save();

      if (role === 'merchant' && businessName) {
        const merchant = new Merchant({ name: businessName, contactInfo: email, status:'pending_approval' });
        const savedMerchant = await merchant.save();
        savedUser.merchantId = savedMerchant._id;
        await savedUser.save();
        user = savedUser;
      }
    }

    if(!user.firebaseUid){
      user.firebaseUid=uid;
      // Repair historical UID-derived credentials only after valid provider authentication.
      if(await bcrypt.compare(uid,user.password)){
        user.password=await bcrypt.hash(crypto.randomBytes(32).toString('hex'),10);
        user.tokenVersion=(user.tokenVersion||0)+1;
        await sessions.revokeAll(user._id);
      }
      await user.save();
    }
    user = await ensureMerchantProfileForUser(user, {
      businessName,
      contactInfo: email,
    });

    const userResponse = user.toObject();
    delete userResponse.password;
    const { token, refreshToken } = await sessions.issue(user);
    res.status(200).json({ ...userResponse, token, refreshToken });
  } catch (error) {
    console.error('Firebase auth error:', error);
    res.status(401).json({ message: 'Invalid Firebase token' });
  }
});

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

// Self-service account deletion (required by App Store guideline 5.1.1(v)).
// Personal data is deleted; merchant-facing records keep counts but lose the person.
router.delete('/me', async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.role === 'admin' && await User.countDocuments({ role: 'admin' }) <= 1) {
      return res.status(409).json({ message: 'Assign another administrator before deleting this account.' });
    }
    const id = user._id;
    const byUserId = ['NotificationPreference', 'NotificationLog', 'DealAlert', 'UserBehaviorEvent', 'UserPreferenceProfile', 'SearchQueryLog']
      .map((name) => require(`../models/${name}`).deleteMany({ userId: id }));
    await Promise.all([
      ...byUserId,
      require('../models/MerchantDraft').deleteMany({ owner: id }),
      require('../models/RefreshSession').deleteMany({ user: id }),
      require('../models/SessionFamily').deleteMany({ user: id }),
      require('../models/PromotionClick').updateMany({ user: id }, { $unset: { user: 1 } }),
      require('../models/Report').updateMany({ reporter: id }, { $unset: { reporter: 1 } }),
      require('../models/Redemption').updateMany({ user: id, status: 'issued' }, { $set: { status: 'cancelled' }, $unset: { issuanceKey: 1 } }),
      Promotion.updateMany(
        { $or: [{ 'comments.user': id }, { 'ratings.user': id }, { 'redemptionFeedback.user': id }] },
        { $pull: { comments: { user: id }, ratings: { user: id }, redemptionFeedback: { user: id } } }),
      Merchant.updateMany(
        { $or: [{ 'ratings.user': id }, { 'reviews.user': id }] },
        { $pull: { ratings: { user: id }, reviews: { user: id } } }),
    ]);
    // A store nobody else manages is hidden, not deleted, so an admin can decide what happens to it.
    if (user.merchantId && !await User.exists({ _id: { $ne: id }, merchantId: user.merchantId })) {
      await Merchant.updateOne({ _id: user.merchantId }, { $set: { status: 'suspended' } });
    }
    await User.deleteOne({ _id: id });
    res.status(200).json({ message: 'Account deleted' });
  } catch (error) {
    console.error('Error deleting own account:', error);
    res.status(500).json(safeError(error));
  }
});

// Delete a user (Admin only)
router.delete('/:id', authorizeAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Optional: Add checks here to prevent deletion of sole admin, etc.
    // For example:
    // if (user.role === 'admin') {
    //   const adminCount = await User.countDocuments({ role: 'admin' });
    //   if (adminCount <= 1 && user.id === req.user.id) { // Comparing authenticated admin with user to be deleted
    //     return res.status(400).json({ message: 'Cannot delete the only admin account.' });
    //   }
    // }

    // TODO: Consider implications of deleting a user.
    // - What happens to their merchant profile if they are a merchant?
    // - What happens to promotions they created?
    // - For now, we will just delete the user document.
    // - In a real application, this might involve cascading deletes or anonymization.

    await User.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json(safeError(error));
  }
});

// Change user password (Self or Admin)
router.post('/:id/change-password', authorizeSelfOrAdmin, [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isString().isByteLength({max:72}).isLength({ min: 8 }).withMessage('New password must be at least 8 characters')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Check current password
    const passwordMatch = await bcrypt.compare(currentPassword, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Invalid current password' });
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedNewPassword;
    user.tokenVersion = (user.tokenVersion || 0) + 1;
    await user.save();
    await sessions.revokeAll(user._id);

    res.status(200).json({ message: 'Password changed successfully' });

  } catch (error) {
    console.error('Error changing password:', error);
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
// Uses gentleAuthenticateJWT to check if an admin is making the request
router.post('/register', gentleAuthenticateJWT, [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isString().isByteLength({max:72}).isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('role').optional().custom((value, { req }) => {
    const allowedRoles = ['user', 'merchant'];
    if (req.user && req.user.role === 'admin') {
      allowedRoles.push('admin');
    }
    if (value && !allowedRoles.includes(value)) {
      throw new Error(`Role must be one of: ${allowedRoles.join(', ')}`);
    }
    return true;
  }),
  body('businessName').optional().isString(),
  body('profilePicture').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    let { name, email, password, role, businessName, profilePicture } = req.body; // Use let for role

    // If an admin is creating a user, they can specify the role.
    // Otherwise, role defaults to 'user' or can be 'merchant'.
    if (req.user && req.user.role === 'admin') {
      // Admin can set role to 'user', 'merchant', or 'admin'
      role = role || 'user'; // Default to user if admin doesn't specify
    } else {
      // Non-admin registration
      if (role && role === 'admin') {
        // Prevent non-admins from setting role to 'admin'
        return res.status(403).json({ message: "Forbidden: Cannot set role to admin." });
      }
      role = role || 'user'; // Default to 'user'
    }
    
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
        status:'pending_approval',
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
    const { token, refreshToken } = await sessions.issue(savedUser);
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
    let user = process.env.DATA_SOURCE === 'postgres'
      ? await findPostgresUserByEmail(email)
      : await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Check password using bcrypt
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    if (process.env.DATA_SOURCE !== 'postgres') {
      user = await ensureMerchantProfileForUser(user, {
        businessName: user.businessName || user.name,
        contactInfo: user.email,
        logo: user.logo,
      });
    }

    // Don't return the password
    const userResponse = user.toObject ? user.toObject() : { ...user };
    delete userResponse.password;
    // Generate tokens
    const { token, refreshToken } = await sessions.issue(user);
    res.status(200).json({ ...userResponse, token, refreshToken });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Refresh token endpoint
router.post('/refresh-token', async (req, res) => {
 try {
  const tokens=await sessions.rotate(req.body.refreshToken);
  if(!tokens)return res.status(401).json({message:'Invalid refresh token'});
  res.json(tokens);
 }catch{return res.status(503).json({message:'Session service unavailable'});}
});
router.post('/logout', async (req,res)=>{
 try {await sessions.revoke(req.body.refreshToken,req.user.id);res.json({message:'Logged out successfully'});}
 catch{return res.status(503).json({message:'Session service unavailable'});}
});

// Update user profile (Self or Admin)
router.put('/:id', authorizeSelfOrAdmin, [
  body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
  body('email').optional().isEmail().withMessage('Valid email is required'),
  body('businessName').optional().isString(),
  body('logo').optional().isString(),
  body('profilePicture').optional().isString(),
  body('preferences').optional().isObject(), // For notification preferences
  body('role').optional().isIn(['user', 'merchant', 'admin']).withMessage('Invalid role specified'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  try {
    const { name, email, businessName, logo, profilePicture, preferences, role } = req.body;

    // Build updateData carefully to avoid unintentionally clearing fields
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (businessName !== undefined) updateData.businessName = businessName;
    if (logo !== undefined) updateData.logo = logo;
    if (profilePicture !== undefined) updateData.profilePicture = profilePicture;
    if (preferences !== undefined) updateData.preferences = preferences;

    // Only allow admin to change role
    if (role !== undefined && req.user.role === 'admin') {
      // Prevent admin from accidentally changing their own role to non-admin if they are the sole admin?
      // For now, allowing it. Could add more checks if needed.
      // Also ensure the target user is not themselves if they are demoting, unless there are other admins.
      // This logic can get complex, for now, trusting admin user.
      updateData.role = role;
    } else if (role !== undefined && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden: Only admins can change user roles.' });
    }

    // Prevent password from being updated here
    if (req.body.password) {
      return res.status(400).json({ message: 'Password cannot be updated through this endpoint. Use /change-password instead.' });
    }

    let updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      { $set: updateData }, // Use $set to only update provided fields
      { new: true }
    ).select('-password');
    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (updatedUser.role === 'merchant' && !updatedUser.merchantId) {
      updatedUser = await ensureMerchantProfileForUser(updatedUser, {
        businessName: businessName || updatedUser.businessName || updatedUser.name,
        contactInfo: email || updatedUser.email,
        logo: logo || updatedUser.logo,
      });
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

    const promotion = await Promotion.findById(promotionId).select('_id');
    if (!promotion) {
      return res.status(404).json({ message: 'Promotion not found' });
    }
    
    // Check if promotion is already in favorites
    if (user.favorites.some(fav => fav.toString() === promotionId.toString())) {
      return res.status(400).json({ message: 'Promotion already in favorites' });
    }
    
    user.favorites.push(promotion._id);
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
      populate: { path: 'merchant', select: '-contactInfo -reviews -ratings -promotions' },
      options: { sort: { updatedAt: -1, createdAt: -1, _id: -1 } }
    });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.status(200).json(user.favorites.filter(Boolean));
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Get followed merchants for a user (Self or Admin)
router.get('/:id/following-merchants', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('followingMerchants')
      .populate('followingMerchants', '-contactInfo -reviews -promotions');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const merchants = Array.isArray(user.followingMerchants)
      ? user.followingMerchants.map(attachMerchantRatingSummary)
      : [];

    res.status(200).json(merchants);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Follow a merchant (Self or Admin)
router.post('/:id/following-merchants', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const { merchantId } = req.body;
    if (!merchantId) {
      return res.status(400).json({ message: 'merchantId is required' });
    }

    const merchant = await Merchant.findById(merchantId);
    if (!merchant) {
      return res.status(404).json({ message: 'Merchant not found' });
    }

    const user = await User.findById(req.params.id).select('followingMerchants');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const alreadyFollowing = user.followingMerchants.some(
      (id) => id.toString() === merchantId.toString()
    );

    if (!alreadyFollowing) {
      user.followingMerchants.push(merchant._id);
      await user.save();
    }

    const followers = await User.countDocuments({ followingMerchants: merchant._id });

    res.status(200).json({
      message: 'Merchant followed successfully',
      merchantId: merchant._id,
      followers,
    });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Unfollow a merchant (Self or Admin)
router.delete('/:id/following-merchants/:merchantId', authorizeSelfOrAdmin, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('followingMerchants');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.followingMerchants = user.followingMerchants.filter(
      (id) => id.toString() !== req.params.merchantId.toString()
    );
    await user.save();

    const followers = await User.countDocuments({
      followingMerchants: req.params.merchantId,
    });

    res.status(200).json({
      message: 'Merchant unfollowed successfully',
      merchantId: req.params.merchantId,
      followers,
    });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Password reset request (step 1)
router.post('/reset-password', async (req, res) => {
  const { email } = req.body;
  if (typeof email !== 'string' || !/\S+@\S+\.\S+/.test(email)) {
    return res.status(400).json({ message: 'Please provide a valid email address.' });
  }
  try {
    if (!process.env.M365_EMAIL || !(process.env.M365_PASSWORD || process.env.EMAIL_PASSWORD)) {
      return res.status(503).json({message:'Password reset email is not configured.'});
    }
    const user = await User.findOne({ email });
    if (!user) {
      // Respond with success even if user not found (to prevent email enumeration)
      return res.status(200).json({ message: 'If your email is registered, you will receive a password reset link.' });
    }
    // Generate a secure random token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetPasswordExpires = Date.now() + 60 * 60 * 1000; // 1 hour
    user.resetPasswordToken = sessions.hash(resetToken);
    user.resetPasswordExpires = resetPasswordExpires;
    await user.save();
    const mailer = require('../mailer');
    const url = new URL('/reset-password', process.env.APP_URL || 'https://dealfinderapp.lk');
    url.searchParams.set('token',resetToken);
    await mailer.sendMail({from:process.env.M365_EMAIL,to:email,subject:'Reset your DealFinder password',
      text:`Use this link within one hour to reset your password: ${url.toString()}`});
    return res.status(200).json({ message: 'If your email is registered, you will receive a password reset link.' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Password reset confirmation (step 2)
router.post('/reset-password/confirm', async (req, res) => {
  const { token, password } = req.body;
  // Strings only: an object like {"$ne": null} would become a Mongo query operator.
  if (typeof token !== 'string' || typeof password !== 'string' || !token || !password) {
    return res.status(400).json({ message: 'Token and new password are required.' });
  }
  if (password.length < 8 || Buffer.byteLength(password,'utf8')>72) {
    return res.status(400).json({ message: 'Password must be at least 8 characters.' });
  }
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.findOneAndUpdate({
      resetPasswordToken: sessions.hash(token), resetPasswordExpires: { $gt: new Date() }
    }, { $set:{password:hashedPassword}, $inc:{tokenVersion:1},
         $unset:{resetPasswordToken:1,resetPasswordExpires:1}}, {new:true});
    if(!user)return res.status(400).json({message:'Invalid or expired token.'});
    await sessions.revokeAll(user._id);
    res.status(200).json({ message: 'Password has been reset successfully.' });
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Google Sign-In
const { OAuth2Client } = require('google-auth-library');
const config = require('../config');
const client = new OAuth2Client(config.GOOGLE_CLIENT_ID);

router.post('/google-signin', async (req, res) => {
    const { token, idToken } = req.body; // Accept both 'token' and 'idToken'
    const googleToken = token || idToken;
    
    if (!googleToken) {
        return res.status(400).json({ message: 'Token or idToken is required' });
    }
    
    try {
        const ticket = await client.verifyIdToken({
            idToken: googleToken,
            audience: config.GOOGLE_CLIENT_ID,
        });
        const { name, email, picture, email_verified } = ticket.getPayload();
        if (email_verified !== true || typeof email !== 'string') return res.status(401).json({ message: 'A verified email identity is required' });

        let user = await User.findOne({ email });
        if (!user) {
            const password = crypto.randomBytes(32).toString('hex'); // unusable; Google users sign in via Google
            const hashedPassword = await bcrypt.hash(password, 10);
            user = new User({
                name,
                email,
                password: hashedPassword,
                profilePicture: picture,
            });
            await user.save();
        }

        user = await ensureMerchantProfileForUser(user, {
            contactInfo: email,
        });

        const userResponse = user.toObject();
        delete userResponse.password;
        const { token: jwtToken, refreshToken } = await sessions.issue(user);
        res.status(200).json({ ...userResponse, token: jwtToken, refreshToken });

    } catch (error) {
        console.error('Google Sign-In error:', error.message);
        res.status(500).json({ message: 'Google Sign-In failed' });
    }
});

// Initialize Merchant Profile for an existing user with role 'merchant' but no merchantId
router.post('/initialize-merchant-profile', authenticateJWT, [
  body('businessName').trim().notEmpty().withMessage('Business name is required.'),
  body('profile').optional().isString(),
  body('contactInfo').optional().isEmail().withMessage('Valid contact email is optional.'),
  body('logo').optional().isURL().withMessage('Logo must be a valid URL.'),
  // Add other merchant fields as necessary from your Merchant model that should be initialized
  body('address').optional().isString(),
  body('contactNumber').optional().isString(),
  // socialMedia can be an object, so specific validation might be more complex if needed here
  body('socialMedia').optional().isObject(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  // Authorization: User must be a merchant and not already have a merchantId
  if (req.user.role !== 'merchant') {
    return res.status(403).json({ message: 'Forbidden: Only users with role merchant can initialize a merchant profile.' });
  }
  if (req.user.merchantId) {
    return res.status(400).json({ message: 'Bad Request: Merchant profile already initialized for this user.' });
  }

  try {
    const { businessName, profile, contactInfo, logo, address, contactNumber, socialMedia } = req.body;
    const userId = req.user.id;

    // 1. Create a new Merchant document
    const newMerchant = new Merchant({
      name: businessName,
      status:'pending_approval',
      profile: profile || '',
      contactInfo: contactInfo || req.user.email, // Default to user's email if not provided
      logo: logo || '',
      address: address || '',
      contactNumber: contactNumber || '',
      socialMedia: socialMedia || {},
      promotions: [] // Initialize with empty promotions
    });
    const savedMerchant = await newMerchant.save();

    // 2. Update the User document with the new merchantId
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $set: { merchantId: savedMerchant._id, businessName: savedMerchant.name } }, // Also save businessName on user for convenience
      { new: true }
    ).select('-password'); // Exclude password from the returned user

    if (!updatedUser) {
      // This should ideally not happen if authenticateJWT worked
      return res.status(404).json({ message: 'User not found after update.' });
    }

    // 3. Generate new tokens as merchantId in JWT payload needs to be updated
    const { token, refreshToken } = await sessions.issue(updatedUser);

    // 4. Respond with updated user object and new tokens
    const userResponse = updatedUser.toObject();
    // merchantId should already be on userResponse due to findByIdAndUpdate and toObject()

    res.status(200).json({
      ...userResponse,
      token,
      refreshToken,
      message: 'Merchant profile initialized successfully.'
    });

  } catch (error) {
    console.error('Error initializing merchant profile:', error);
    res.status(500).json(safeError(error));
  }
});

module.exports = router;
