module.exports = (sequelize, DataTypes) => {
  const PromotionRating = sequelize.define('PromotionRating', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    value: { type: DataTypes.SMALLINT, allowNull: false, validate: { min: 1, max: 5 } },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'promotion_ratings',
    timestamps: false,
  });

  PromotionRating.associate = (models) => {
    PromotionRating.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    PromotionRating.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return PromotionRating;
};
