const jwt = require('jsonwebtoken');
const User = require('../models/User'); // May be needed for more complex role checks if not on JWT

async function resolveMerchantIdFromUser(userPayload) {
  if (!userPayload?.id) return null;

  try {
    const dbUser = await User.findById(userPayload.id).select('merchantId');
    return dbUser?.merchantId ? dbUser.merchantId.toString() : null;
  } catch (_) {
    return null;
  }
}

async function verifiedUser(req) {
 const header=req.headers.authorization;
 if(typeof header!=='string'||!header.startsWith('Bearer '))return null;
 const payload=jwt.verify(header.slice(7),process.env.JWT_SECRET,{algorithms:['HS256']});
 if(!payload || typeof payload.id!=='string' || typeof payload.sid!=='string' || typeof payload.tokenVersion!=='number')return null;
 let account;
 if(process.env.DATA_SOURCE==='postgres'){
  const pg=require('../models-pg');account=await pg.User.findByPk(payload.id);
 }else account=await User.findById(payload.id).select('role merchantId tokenVersion');
 if(!account || account.role!==payload.role || (account.tokenVersion||0)!==(payload.tokenVersion||0))return null;
 if(payload.sid){
  const Family=require('../models/SessionFamily');
  if(!await Family.exists({_id:payload.sid,user:payload.id,revokedAt:null,expiresAt:{$gt:new Date()}}))return null;
 }
 return {...payload,role:account.role,merchantId:account.merchantId};
}
async function authenticateJWT(req,res,next){
 if(!req.headers.authorization)return res.status(401).json({message:'Authorization token required'});
 try{const user=await verifiedUser(req);if(!user)return res.status(403).json({message:'Invalid or expired token'});req.user=user;next();}
 catch{return res.status(403).json({message:'Invalid or expired token'});}
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
  if (req.user && (req.user.id.toString() === req.params.id.toString() || req.user.role === 'admin')) {
    next();
  } else {
    res.status(403).json({ message: 'Forbidden: You do not have permission to access this resource' });
  }
}

// Authorization Middleware: User is a merchant and owns the resource, or is an Admin
// This will require fetching the resource (e.g., Promotion, Merchant profile) first to check ownership.
// So, this might be better implemented directly in routes or as a more specialized middleware.
// For now, let's define a simpler one for merchant's own profile.
async function authorizeMerchantSelfOrAdmin(req,res,next) {
 if(req.user?.role==='admin')return next();
 if(req.user?.role!=='merchant')return res.status(403).json({message:'Merchant access required'});
 try {
  if(process.env.DATA_SOURCE==='postgres') {
   if(req.user.merchantId&&String(req.user.merchantId)===String(req.params.id))return next();
  }else {
   const account=await User.findById(req.user.id).select('merchantId role');
   if(account?.role==='merchant'&&String(account.merchantId)===String(req.params.id)){req.user.merchantId=account.merchantId;return next();}
  }
  return res.status(403).json({message:'Forbidden: You do not own this merchant resource'});
 }catch{return res.status(500).json({message:'Unable to authorize merchant access'});}
}

// Optional JWT Middleware (sets req.user if token valid, but doesn't fail if not present/invalid)
async function gentleAuthenticateJWT(req,res,next){
 try{const user=await verifiedUser(req);if(user)req.user=user;}catch{}
 next();
}

// Authorization Middleware: User owns the promotion (is the merchant for it), or is an Admin
async function authorizePromotionOwnerOrAdmin(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ message: 'Authentication required' });
  }

  if (req.user.role === 'admin') {
    return next();
  }

  if (req.user.role === 'merchant') {
    try {
      req.user.merchantId = await resolveMerchantIdFromUser(req.user);

      if (!req.user.merchantId) {
        return res.status(403).json({ message: 'Forbidden: No merchant profile is linked to this account' });
      }

      if (process.env.DATA_SOURCE === 'postgres') {
        const { getPromotionByIdFromPostgres } = require('../services/postgresPromotionService');
        const promotion = await getPromotionByIdFromPostgres(req.params.id);
        if (!promotion) {
          return res.status(404).json({ message: 'Promotion not found' });
        }
        if (promotion.merchant?._id === req.user.merchantId.toString()) {
          return next();
        }
        return res.status(403).json({ message: 'Forbidden: You do not own this promotion' });
      }

      const Promotion = require('../models/Promotion');
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
      return res.status(500).json({ message: 'Error authorizing promotion access' });
    }
  } else {
    return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
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
