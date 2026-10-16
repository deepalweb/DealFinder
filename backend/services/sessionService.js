const crypto=require('crypto');
const jwt=require('jsonwebtoken');
const RefreshSession=require('../models/RefreshSession');
const User=require('../models/User');
const Family=require('../models/SessionFamily');
const hash=value=>crypto.createHash('sha256').update(value).digest('hex');
function accessToken(user,family){
 return jwt.sign({id:user._id,email:user.email,role:user.role,merchantId:user.merchantId,
  tokenVersion:user.tokenVersion||0,sid:family},process.env.JWT_SECRET,{expiresIn:'7d',algorithm:'HS256'});
}
async function issue(user,family){
 if(!family){family=crypto.randomUUID();await Family.create({_id:family,user:user._id,expiresAt:new Date(Date.now()+30*86400000)});}
 else if(!await Family.exists({_id:family,user:user._id,revokedAt:null,expiresAt:{$gt:new Date()}}))return null;
 const refreshToken=jwt.sign({id:user._id,sid:family,jti:crypto.randomUUID(),tokenVersion:user.tokenVersion||0},
  process.env.JWT_REFRESH_SECRET,{expiresIn:'30d',algorithm:'HS256'});
 await RefreshSession.create({user:user._id,family,tokenHash:hash(refreshToken),
  tokenVersion:user.tokenVersion||0,expiresAt:new Date(jwt.decode(refreshToken).exp*1000)});
 return {token:accessToken(user,family),refreshToken};
}
async function rotate(token){
 if(typeof token!=='string'||token.length>4096) return null;
 let payload;try{payload=jwt.verify(token,process.env.JWT_REFRESH_SECRET,{algorithms:['HS256']});}catch{return null;}
 if(!payload.sid || !await Family.exists({_id:payload.sid,user:payload.id,revokedAt:null,expiresAt:{$gt:new Date()}}))return null;
 const now=new Date();
 const row=await RefreshSession.findOneAndUpdate({tokenHash:hash(token),revokedAt:null,expiresAt:{$gt:now}},{$set:{revokedAt:now}},{new:true});
 if(!row){await Family.updateOne({_id:payload.sid},{$set:{revokedAt:now}});await RefreshSession.updateMany({family:payload.sid},{$set:{revokedAt:now}});return null;}
 const user=await User.findById(payload.id);
 if(!user||row.tokenVersion!==(user.tokenVersion||0))return null;
 return issue(user,row.family);
}
async function revoke(token,userId){
 if(typeof token!=='string')return;
 const row=await RefreshSession.findOne({tokenHash:hash(token),user:userId});
 if(row){await Family.updateOne({_id:row.family,user:userId},{$set:{revokedAt:new Date()}});await RefreshSession.updateMany({family:row.family},{$set:{revokedAt:new Date()}});}
}
async function revokeAll(userId){
 await Family.updateMany({user:userId},{$set:{revokedAt:new Date()}});await RefreshSession.updateMany({user:userId},{$set:{revokedAt:new Date()}});
 // Firebase sessions too, or a signed-in device could exchange a Firebase token for a new session.
 const account=await require('../models/User').findById(userId).select('+firebaseUid').lean();
 const {admin,ensureFirebaseAdminInitialized}=require('./firebaseAdmin');
 if(account?.firebaseUid&&ensureFirebaseAdminInitialized())await admin.auth().revokeRefreshTokens(account.firebaseUid).catch(()=>{});
}
module.exports={issue,rotate,revoke,revokeAll,hash};
