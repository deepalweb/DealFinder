module.exports = (sequelize, DataTypes) => {
  const Merchant = sequelize.define('Merchant', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    name: { type: DataTypes.TEXT, allowNull: false, unique: true },
    profile: DataTypes.TEXT,
    description: DataTypes.TEXT,
    category: DataTypes.TEXT,
    merchantType: { type: DataTypes.TEXT, field: 'merchant_type', defaultValue: 'offline' },
    website: DataTypes.TEXT,
    orderLink: { type: DataTypes.TEXT, field: 'order_link' },
    deliveryAvailable: { type: DataTypes.BOOLEAN, field: 'delivery_available', defaultValue: false },
    pickupAvailable: { type: DataTypes.BOOLEAN, field: 'pickup_available', defaultValue: false },
    openingHours: { type: DataTypes.JSONB, field: 'opening_hours' },
    contactInfo: { type: DataTypes.JSONB, field: 'contact_info' },
    logo: DataTypes.TEXT,
    banner: DataTypes.TEXT,
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    address: DataTypes.TEXT,
    contactNumber: { type: DataTypes.TEXT, field: 'contact_number' },
    socialMedia: { type: DataTypes.JSONB, field: 'social_media' },
    status: { type: DataTypes.TEXT, defaultValue: 'active' },
    currency: { type: DataTypes.TEXT, defaultValue: 'USD' },
    locationGeog: { type: DataTypes.GEOGRAPHY('POINT', 4326), field: 'location_geog' },
  }, {
    tableName: 'merchants',
    timestamps: false,
  });

  Merchant.associate = (models) => {
    Merchant.hasMany(models.Promotion, { foreignKey: 'merchantId' });
    Merchant.hasMany(models.MerchantRating, { foreignKey: 'merchantId', as: 'ratings' });
    Merchant.hasMany(models.MerchantReview, { foreignKey: 'merchantId', as: 'reviews' });
    Merchant.belongsToMany(models.BankOffer, { through: 'bank_offer_applicable_merchants', foreignKey: 'merchant_id', otherKey: 'bank_offer_id', timestamps: false });
    Merchant.belongsToMany(models.User, { through: 'user_following_merchants', as: 'followers', foreignKey: 'merchant_id', otherKey: 'user_id', timestamps: false });
  };

  return Merchant;
};
