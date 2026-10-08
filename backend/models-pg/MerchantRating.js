module.exports = (sequelize, DataTypes) => {
  const MerchantRating = sequelize.define('MerchantRating', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id', allowNull: false },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    value: { type: DataTypes.SMALLINT, allowNull: false, validate: { min: 1, max: 5 } },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'merchant_ratings',
    timestamps: false,
  });

  MerchantRating.associate = (models) => {
    MerchantRating.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    MerchantRating.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return MerchantRating;
};
