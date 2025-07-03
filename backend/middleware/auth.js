const jwt = require('jsonwebtoken');
const User = require('../models/User'); // May be needed for more complex role checks if not on JWT

// JWT Middleware
function authenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret', (err, user) => {
      if (err) {
        // console.error("JWT Verification Error:", err.message);
        return res.status(403).json({ message: 'Invalid or expired token' });
      }
      req.user = user; // user payload from JWT (id, email, role)
      next();
    });
  } else {
    res.status(401).json({ message: 'Authorization token required' });
  }
}

// Authorization Middleware: Admin only
function authorizeAdmin(req, res, next) {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Forbidden: Admin access required' });
  }
}

// Authorization Middleware: User is accessing/modifying their own resource, or is an Admin
function authorizeSelfOrAdmin(req, res, next) {
  // Assumes route has an :id parameter that is the user's ID
  if (req.user && (req.user.id === req.params.id || req.user.role === 'admin')) {
    next();
  } else {
    res.status(403).json({ message: 'Forbidden: You do not have permission to access this resource' });
  }
}

// Authorization Middleware: User is a merchant and owns the resource, or is an Admin
// This will require fetching the resource (e.g., Promotion, Merchant profile) first to check ownership.
// So, this might be better implemented directly in routes or as a more specialized middleware.
// For now, let's define a simpler one for merchant's own profile.
function authorizeMerchantSelfOrAdmin(req, res, next) {
  // Assumes route has an :id parameter that is the merchant's ID (from Merchant model)
  // and req.user.merchantId is populated if the user's role is 'merchant'
  if (req.user &&
      (req.user.role === 'admin' ||
       (req.user.role === 'merchant' && req.user.merchantId && req.user.merchantId.toString() === req.params.id))) {
    next();
  } else {
    res.status(403).json({ message: 'Forbidden: You do not have permission to access this merchant resource' });
  }
}


module.exports = {
  authenticateJWT,
  authorizeAdmin,
  authorizeSelfOrAdmin,
  authorizeMerchantSelfOrAdmin,
  authorizePromotionOwnerOrAdmin,
  gentleAuthenticateJWT,
};

// Optional JWT Middleware (sets req.user if token valid, but doesn't fail if not present/invalid)
function gentleAuthenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret', (err, user) => {
      if (!err) {
        req.user = user;
      } // If error, just proceed without req.user
      next();
    });
  } else {
    next();
  }
}

// Authorization Middleware: User owns the promotion (is the merchant for it), or is an Admin
async function authorizePromotionOwnerOrAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ message: 'Authentication required' });
  }

  if (req.user.role === 'admin') {
    return next();
  }

  if (req.user.role === 'merchant' && req.user.merchantId) {
    try {
      const Promotion = require('../models/Promotion'); // Local require to avoid circular deps if any
      const promotion = await Promotion.findById(req.params.id);
      if (!promotion) {
        return res.status(404).json({ message: 'Promotion not found' });
      }
      if (promotion.merchant.toString() === req.user.merchantId.toString()) {
        return next();
      } else {
        return res.status(403).json({ message: 'Forbidden: You do not own this promotion' });
      }
    } catch (error) {
      // console.error("Error in authorizePromotionOwnerOrAdmin:", error);
      return res.status(500).json({ message: 'Error authorizing promotion access' });
    }
  } else {
    return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
  }
}
