module.exports = (sequelize, DataTypes) => {
  const PromotionComment = sequelize.define('PromotionComment', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    text: { type: DataTypes.TEXT, allowNull: false },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'promotion_comments',
    timestamps: false,
  });

  PromotionComment.associate = (models) => {
    PromotionComment.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    PromotionComment.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return PromotionComment;
};
