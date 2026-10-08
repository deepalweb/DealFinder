module.exports = (sequelize, DataTypes) => {
  const Promotion = sequelize.define('Promotion', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    title: { type: DataTypes.TEXT, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: false },
    discount: { type: DataTypes.TEXT, allowNull: false },
    code: { type: DataTypes.TEXT, allowNull: false },
    category: { type: DataTypes.TEXT, allowNull: false },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id', allowNull: false },
    startDate: { type: DataTypes.DATE, field: 'start_date', allowNull: false },
    endDate: { type: DataTypes.DATE, field: 'end_date', allowNull: false },
    images: DataTypes.JSONB,
    image: DataTypes.TEXT,
    url: DataTypes.TEXT,
    fulfillmentType: { type: DataTypes.TEXT, field: 'fulfillment_type', defaultValue: 'visit' },
    orderLink: { type: DataTypes.TEXT, field: 'order_link' },
    visitAvailable: { type: DataTypes.BOOLEAN, field: 'visit_available', defaultValue: true },
    deliveryAvailable: { type: DataTypes.BOOLEAN, field: 'delivery_available', defaultValue: false },
    pickupAvailable: { type: DataTypes.BOOLEAN, field: 'pickup_available', defaultValue: false },
    featured: { type: DataTypes.BOOLEAN, defaultValue: false },
    originalPrice: { type: DataTypes.DECIMAL, field: 'original_price' },
    discountedPrice: { type: DataTypes.DECIMAL, field: 'discounted_price' },
    bankName: { type: DataTypes.TEXT, field: 'bank_name' },
    cardTypes: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'card_types' },
    offerType: { type: DataTypes.TEXT, field: 'offer_type' },
    minimumSpend: { type: DataTypes.DECIMAL, field: 'minimum_spend' },
    maximumBenefit: { type: DataTypes.DECIMAL, field: 'maximum_benefit' },
    status: { type: DataTypes.TEXT, defaultValue: 'draft' },
    adminVerified: { type: DataTypes.BOOLEAN, field: 'admin_verified', defaultValue: false },
    verifiedAt: { type: DataTypes.DATE, field: 'verified_at' },
    verifiedBy: { type: DataTypes.TEXT, field: 'verified_by' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'promotions',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  Promotion.associate = (models) => {
    Promotion.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    Promotion.belongsTo(models.User, { foreignKey: 'verifiedBy', as: 'verifier' });
    Promotion.hasMany(models.PromotionComment, { foreignKey: 'promotionId', as: 'comments' });
    Promotion.hasMany(models.PromotionRating, { foreignKey: 'promotionId', as: 'ratings' });
    Promotion.hasMany(models.PromotionRedemptionFeedback, { foreignKey: 'promotionId', as: 'redemptionFeedback' });
    Promotion.belongsToMany(models.User, { through: 'user_favorites', as: 'favoritedBy', foreignKey: 'promotion_id', otherKey: 'user_id', timestamps: false });
  };

  return Promotion;
};
