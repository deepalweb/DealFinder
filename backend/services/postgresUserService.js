// Minimal Postgres-backed auth lookup, matching the Mongo-backed login route's shape.
// Gated behind DATA_SOURCE=postgres — used only for local dev/demo login.
const pg = require('../models-pg');

async function findUserByEmail(email) {
  const user = await pg.User.findOne({ where: { email } });
  if (!user) return null;

  const u = user.toJSON();
  return {
    _id: u.id,
    id: u.id,
    name: u.name,
    email: u.email,
    password: u.password,
    role: u.role,
    merchantId: u.merchantId,
    businessName: u.businessName,
    createdAt: u.createdAt,
    logo: u.logo,
    profilePicture: u.profilePicture,
    pushSubscription: u.pushSubscription,
    preferences: u.preferences,
  };
}

module.exports = { findUserByEmail };
