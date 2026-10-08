module.exports = (sequelize, DataTypes) => {
  const UserPreferenceCategory = sequelize.define('UserPreferenceCategory', {
    userId: { type: DataTypes.TEXT, field: 'user_id', allowNull: false, primaryKey: true },
    category: { type: DataTypes.TEXT, allowNull: false, primaryKey: true },
  }, {
    tableName: 'user_preference_categories',
    timestamps: false,
  });

  UserPreferenceCategory.associate = (models) => {
    UserPreferenceCategory.belongsTo(models.User, { foreignKey: 'userId' });
  };

  return UserPreferenceCategory;
};
