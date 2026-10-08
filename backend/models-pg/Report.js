module.exports = (sequelize, DataTypes) => {
  const Report = sequelize.define('Report', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    targetType: { type: DataTypes.TEXT, field: 'target_type', allowNull: false },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id' },
    merchantId: { type: DataTypes.TEXT, field: 'merchant_id' },
    reporter: { type: DataTypes.TEXT },
    resolvedBy: { type: DataTypes.TEXT, field: 'resolved_by' },
    reason: DataTypes.TEXT,
    description: DataTypes.TEXT,
    status: DataTypes.TEXT,
    resolutionNote: { type: DataTypes.TEXT, field: 'resolution_note' },
    resolvedAt: { type: DataTypes.DATE, field: 'resolved_at' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'reports',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  Report.associate = (models) => {
    Report.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    Report.belongsTo(models.Merchant, { foreignKey: 'merchantId' });
    Report.belongsTo(models.User, { foreignKey: 'reporter', as: 'reporterUser' });
    Report.belongsTo(models.User, { foreignKey: 'resolvedBy', as: 'resolver' });
  };

  return Report;
};
