module.exports = (sequelize, DataTypes) => {
  const NotificationLog = sequelize.define('NotificationLog', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false },
    type: { type: DataTypes.TEXT, allowNull: false },
    title: { type: DataTypes.TEXT, allowNull: false },
    body: { type: DataTypes.TEXT, allowNull: false },
    data: { type: DataTypes.JSONB, defaultValue: {} },
    channels: DataTypes.ARRAY(DataTypes.TEXT),
    statusPushSent: { type: DataTypes.BOOLEAN, field: 'status_push_sent', defaultValue: false },
    statusPushDelivered: { type: DataTypes.BOOLEAN, field: 'status_push_delivered', defaultValue: false },
    statusPushOpened: { type: DataTypes.BOOLEAN, field: 'status_push_opened', defaultValue: false },
    statusPushError: { type: DataTypes.TEXT, field: 'status_push_error' },
    statusEmailSent: { type: DataTypes.BOOLEAN, field: 'status_email_sent', defaultValue: false },
    statusEmailOpened: { type: DataTypes.BOOLEAN, field: 'status_email_opened', defaultValue: false },
    statusEmailError: { type: DataTypes.TEXT, field: 'status_email_error' },
    statusWebSent: { type: DataTypes.BOOLEAN, field: 'status_web_sent', defaultValue: false },
    statusWebClicked: { type: DataTypes.BOOLEAN, field: 'status_web_clicked', defaultValue: false },
    statusWebError: { type: DataTypes.TEXT, field: 'status_web_error' },
    priority: { type: DataTypes.TEXT, defaultValue: 'normal' },
    read: { type: DataTypes.BOOLEAN, defaultValue: false },
    readAt: { type: DataTypes.DATE, field: 'read_at' },
    sentAt: { type: DataTypes.DATE, field: 'sent_at' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'notification_logs',
    timestamps: false,
  });

  NotificationLog.associate = (models) => {
    NotificationLog.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return NotificationLog;
};
