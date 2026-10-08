module.exports = (sequelize, DataTypes) => {
  const DealAlert = sequelize.define('DealAlert', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    alertTypes: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'alert_types' },
    active: { type: DataTypes.BOOLEAN, defaultValue: true },
    lastExpiryNotifiedAt: { type: DataTypes.DATE, field: 'last_expiry_notified_at' },
    lastPriceDropNotifiedAt: { type: DataTypes.DATE, field: 'last_price_drop_notified_at' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'deal_alerts',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  DealAlert.associate = (models) => {
    DealAlert.belongsTo(models.User, { foreignKey: 'userId' });
    DealAlert.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
  };

  return DealAlert;
};
