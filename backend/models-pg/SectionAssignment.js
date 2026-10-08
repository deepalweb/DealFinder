module.exports = (sequelize, DataTypes) => {
  const SectionAssignment = sequelize.define('SectionAssignment', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    sectionKey: { type: DataTypes.TEXT, field: 'section_key', allowNull: false },
    promotionId: { type: DataTypes.TEXT, field: 'promotion_id', allowNull: false },
    mode: DataTypes.TEXT,
    metadata: { type: DataTypes.JSONB, defaultValue: {} },
    updatedBy: { type: DataTypes.TEXT, field: 'updated_by' },
    enabled: { type: DataTypes.BOOLEAN, defaultValue: true },
    priority: { type: DataTypes.INTEGER, defaultValue: 0 },
    startAt: { type: DataTypes.DATE, field: 'start_at' },
    endAt: { type: DataTypes.DATE, field: 'end_at' },
    bannerImageUrl: { type: DataTypes.TEXT, field: 'banner_image_url' },
    radiusKm: { type: DataTypes.DECIMAL, field: 'radius_km' },
    minDistanceKm: { type: DataTypes.DECIMAL, field: 'min_distance_km' },
    maxDistanceKm: { type: DataTypes.DECIMAL, field: 'max_distance_km' },
    excludeFromAuto: { type: DataTypes.BOOLEAN, field: 'exclude_from_auto', defaultValue: false },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'section_assignments',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  SectionAssignment.associate = (models) => {
    SectionAssignment.belongsTo(models.Promotion, { foreignKey: 'promotionId' });
    SectionAssignment.belongsTo(models.User, { foreignKey: 'updatedBy', as: 'updater' });
  };

  return SectionAssignment;
};
