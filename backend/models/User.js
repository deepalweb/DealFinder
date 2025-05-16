const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { 
    type: String, 
    enum: ['user', 'merchant', 'admin'],
    default: 'user'
  },
  merchantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Merchant' },
  businessName: { type: String },
  favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Promotion' }],
  createdAt: { type: Date, default: Date.now },
  logo: { type: String }, // Add logo field for user profile image
  resetPasswordToken: { type: String },
  resetPasswordExpires: { type: Date },
  profilePicture: { type: String }, // base64 or URL for user profile image
});

module.exports = mongoose.model('User', userSchema);