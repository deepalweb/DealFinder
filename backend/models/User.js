const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  firebaseUid: {type:String,unique:true,sparse:true,select:false},
  tokenVersion: { type: Number, default: 0 },
  role: { 
    type: String, 
    enum: ['user', 'merchant', 'admin'],
    default: 'user'
  },
  merchantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant' },
  followingMerchants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Merchant' }],
  businessName: { type: String },
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  createdAt: { type: Date, default: Date.now },
  logo: { type: String }, // Add logo field for user profile image
  resetPasswordToken: { type: String, select: false },
  resetPasswordExpires: { type: Date, select: false },
  profilePicture: { type: String }, // base64 or URL for user profile image
  preferences: {
    notifications: {
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: false },
      expiringDeals: { type: Boolean, default: true },
      favoriteStores: { type: Boolean, default: true },
      recommendations: { type: Boolean, default: true },
    }
  },
  pushSubscription: {
    type: Object
  }
});

function redact(_doc,ret){
 for(const key of ['password','firebaseUid','resetPasswordToken','resetPasswordExpires','tokenVersion'])delete ret[key];
 return ret;
}
userSchema.set('toJSON',{transform:redact});
userSchema.set('toObject',{transform:redact});
module.exports = mongoose.model('User', userSchema);
