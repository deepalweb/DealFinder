module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    name: { type: DataTypes.TEXT, allowNull: false },
    email: { type: DataTypes.TEXT, allowNull: false, unique: true },
    password: { type: DataTypes.TEXT, allowNull: false },
    role: { type: DataTypes.TEXT, defaultValue: 'user' },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id' },
    businessName: { type: DataTypes.TEXT, field: 'business_name' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    logo: DataTypes.TEXT,
    resetPasswordToken: { type: DataTypes.TEXT, field: 'reset_password_token' },
    resetPasswordExpires: { type: DataTypes.DATE, field: 'reset_password_expires' },
    profilePicture: { type: DataTypes.TEXT, field: 'profile_picture' },
    pushSubscription: { type: DataTypes.JSONB, field: 'push_subscription' },
    preferences: DataTypes.JSONB,
  }, {
    tableName: 'users',
    timestamps: false,
  });

  User.associate = (models) => {
    User.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    User.belongsToMany(models.Merchant, { through: 'user_following_merchants', as: 'followingMerchants', foreignKey: 'user_id', otherKey: 'merchant_id', timestamps: false });
    User.belongsToMany(models.Promotion, { through: 'user_favorites', as: 'favorites', foreignKey: 'user_id', otherKey: 'promotion_id', timestamps: false });
    User.hasMany(models.UserPreferenceCategory, { foreignKey: 'userId' });
  };

  return User;
};
