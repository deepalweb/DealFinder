module.exports = (sequelize, DataTypes) => {
  const NotificationPreference = sequelize.define('NotificationPreference', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false, unique: true },
    pushEnabled: { type: DataTypes.BOOLEAN, field: 'push_enabled', defaultValue: false },
    pushToken: { type: DataTypes.TEXT, field: 'push_token' },
    emailEnabled: { type: DataTypes.BOOLEAN, field: 'email_enabled', defaultValue: true },
    webEnabled: { type: DataTypes.BOOLEAN, field: 'web_enabled', defaultValue: false },
    webSubscription: { type: DataTypes.JSONB, field: 'web_subscription' },
    preferences: DataTypes.JSONB,
    quietHours: { type: DataTypes.JSONB, field: 'quiet_hours' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'notification_preferences',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  NotificationPreference.associate = (models) => {
    NotificationPreference.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return NotificationPreference;
};
