module.exports = (sequelize, DataTypes) => {
  const MerchantReview = sequelize.define('MerchantReview', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    text: { type: DataTypes.TEXT, allowNull: false },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'merchant_reviews',
    timestamps: false,
  });

  MerchantReview.associate = (models) => {
    MerchantReview.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    MerchantReview.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return MerchantReview;
};
