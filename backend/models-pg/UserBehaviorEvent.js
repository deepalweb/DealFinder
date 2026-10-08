module.exports = (sequelize, DataTypes) => {
  const UserBehaviorEvent = sequelize.define('UserBehaviorEvent', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    userId: { type: DataTypes.TEXT, field: 'user_id' },
    sessionId: { type: DataTypes.TEXT, field: 'session_id' },
    platform: DataTypes.TEXT,
    eventType: { type: DataTypes.TEXT, field: 'event_type' },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id' },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id' },
    category: DataTypes.TEXT,
    query: DataTypes.TEXT,
    filters: DataTypes.JSONB,
    metadata: DataTypes.JSONB,
    latitude: DataTypes.DECIMAL,
    longitude: DataTypes.DECIMAL,
    radiusKm: { type: DataTypes.DECIMAL, field: 'radius_km' },
    label: DataTypes.TEXT,
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'user_behavior_events',
    timestamps: false,
  });

  UserBehaviorEvent.associate = (models) => {
    UserBehaviorEvent.belongsTo(models.User, { foreignKey: 'userId' });
    UserBehaviorEvent.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    UserBehaviorEvent.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
  };

  return UserBehaviorEvent;
};
