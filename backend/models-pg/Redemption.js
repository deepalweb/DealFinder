module.exports = (sequelize, DataTypes) => {
  const Redemption = sequelize.define('Redemption', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    token: { type: DataTypes.TEXT, allowNull: false, unique: true },
    status: { type: DataTypes.TEXT, defaultValue: 'issued' },
    expiresAt: { type: DataTypes.DATE, field: 'expires_at' },
    redeemedAt: { type: DataTypes.DATE, field: 'redeemed_at' },
    redeemedBy: { type: DataTypes.TEXT, field: 'redeemed_by' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'redemptions',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  Redemption.associate = (models) => {
    Redemption.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    Redemption.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    Redemption.belongsTo(models.User, { foreignKey: 'userId' });
    Redemption.belongsTo(models.User, { foreignKey: 'redeemedBy', as: 'redeemer' });
  };

  return Redemption;
};
