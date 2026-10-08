module.exports = (sequelize, DataTypes) => {
  const UserPreferenceProfile = sequelize.define('UserPreferenceProfile', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false, unique: true },
    categoryAffinity: { type: DataTypes.JSONB, field: 'category_affinity' },
    merchantAffinity: { type: DataTypes.JSONB, field: 'merchant_affinity' },
    topMerchantIds: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'top_merchant_ids' },
    topCategories: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'top_categories' },
    topQueryTerms: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'top_query_terms' },
    preferredRadiusKm: { type: DataTypes.DECIMAL, field: 'preferred_radius_km', defaultValue: 10 },
    lastActiveAt: { type: DataTypes.DATE, field: 'last_active_at' },
    latitude: DataTypes.DECIMAL,
    longitude: DataTypes.DECIMAL,
    locationUpdatedAt: { type: DataTypes.DATE, field: 'location_updated_at' },
    segmentName: { type: DataTypes.TEXT, field: 'segment_name' },
    segmentConfidence: { type: DataTypes.DECIMAL, field: 'segment_confidence' },
    statsSearchCount: { type: DataTypes.INTEGER, field: 'stats_search_count', defaultValue: 0 },
    statsViewCount: { type: DataTypes.INTEGER, field: 'stats_view_count', defaultValue: 0 },
    statsClickCount: { type: DataTypes.INTEGER, field: 'stats_click_count', defaultValue: 0 },
    statsFavoriteCount: { type: DataTypes.INTEGER, field: 'stats_favorite_count', defaultValue: 0 },
    statsNearbySearchCount: { type: DataTypes.INTEGER, field: 'stats_nearby_search_count', defaultValue: 0 },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'user_preference_profiles',
    timestamps: true,
    createdAt: false,
    updatedAt: 'updatedAt',
  });

  UserPreferenceProfile.associate = (models) => {
    UserPreferenceProfile.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return UserPreferenceProfile;
};
