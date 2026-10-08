module.exports = (sequelize, DataTypes) => {
  const SearchQueryLog = sequelize.define('SearchQueryLog', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    userId: { type: DataTypes.TEXT, field: 'user_id' },
    sessionId: { type: DataTypes.TEXT, field: 'session_id' },
    query: DataTypes.TEXT,
    explicitFilters: { type: DataTypes.JSONB, field: 'explicit_filters' },
    interpretedFilters: { type: DataTypes.JSONB, field: 'interpreted_filters' },
    latitude: DataTypes.DECIMAL,
    longitude: DataTypes.DECIMAL,
    radiusKm: { type: DataTypes.DECIMAL, field: 'radius_km' },
    resultCount: { type: DataTypes.INTEGER, field: 'result_count', defaultValue: 0 },
    aiUsed: { type: DataTypes.BOOLEAN, field: 'ai_used', defaultValue: false },
    fallbackUsed: { type: DataTypes.BOOLEAN, field: 'fallback_used', defaultValue: false },
    latencyMs: { type: DataTypes.INTEGER, field: 'latency_ms', defaultValue: 0 },
    topPromotionIds: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'top_promotion_ids' },
    normalizedQuery: { type: DataTypes.TEXT, field: 'normalized_query' },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'search_query_logs',
    timestamps: false,
  });

  SearchQueryLog.associate = (models) => {
    SearchQueryLog.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return SearchQueryLog;
};
