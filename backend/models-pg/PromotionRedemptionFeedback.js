module.exports = (sequelize, DataTypes) => {
  const PromotionRedemptionFeedback = sequelize.define('PromotionRedemptionFeedback', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    worked: { type: DataTypes.BOOLEAN, allowNull: false },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'promotion_redemption_feedback',
    timestamps: false,
  });

  PromotionRedemptionFeedback.associate = (models) => {
    PromotionRedemptionFeedback.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    PromotionRedemptionFeedback.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return PromotionRedemptionFeedback;
};
