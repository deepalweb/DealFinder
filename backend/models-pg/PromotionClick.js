module.exports = (sequelize, DataTypes) => {
  const PromotionClick = sequelize.define('PromotionClick', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id' },
    timestamp: { type: DataTypes.DATE, field: 'timestamp', defaultValue: DataTypes.NOW },
    type: { type: DataTypes.TEXT, defaultValue: 'click' },
  }, {
    tableName: 'promotion_clicks',
    timestamps: false,
  });

  PromotionClick.associate = (models) => {
    PromotionClick.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    PromotionClick.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    PromotionClick.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return PromotionClick;
};
