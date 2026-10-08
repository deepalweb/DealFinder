module.exports = (sequelize, DataTypes) => {
  const BankOffer = sequelize.define('BankOffer', {
    id: { type: DataTypes.TEXT, primaryKey: true },
    title: DataTypes.TEXT,
    description: DataTypes.TEXT,
    discount: DataTypes.TEXT,
    code: DataTypes.TEXT,
    bankName: { type: DataTypes.TEXT, field: 'bank_name' },
    cardTypes: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'card_types' },
    offerType: { type: DataTypes.TEXT, field: 'offer_type' },
    applicableCategories: { type: DataTypes.ARRAY(DataTypes.TEXT), field: 'applicable_categories' },
    minimumSpend: { type: DataTypes.DECIMAL, field: 'minimum_spend' },
    maximumBenefit: { type: DataTypes.DECIMAL, field: 'maximum_benefit' },
    termsAndConditions: { type: DataTypes.TEXT, field: 'terms_and_conditions' },
    image: DataTypes.TEXT,
    images: DataTypes.JSONB,
    url: DataTypes.TEXT,
    featured: { type: DataTypes.BOOLEAN, defaultValue: false },
    isSponsored: { type: DataTypes.BOOLEAN, field: 'is_sponsored', defaultValue: true },
    priority: { type: DataTypes.INTEGER, defaultValue: 0 },
    status: { type: DataTypes.TEXT, defaultValue: 'draft' },
    startDate: { type: DataTypes.DATE, field: 'start_date' },
    endDate: { type: DataTypes.DATE, field: 'end_date' },
    createdBy: { type: DataTypes.TEXT, field: 'created_by' },
    updatedBy: { type: DataTypes.TEXT, field: 'updated_by' },
    category: {
      type: DataTypes.TEXT,
      set(value) {
        if (!this.isNewRecord && this.getDataValue('category') !== undefined && this.getDataValue('category') !== value) {
          throw new Error('BankOffer.category is immutable and cannot be changed after creation.');
        }
        this.setDataValue('category', value);
      },
    },
    createdAt: { type: DataTypes.DATE, field: 'created_at', defaultValue: DataTypes.NOW },
    updatedAt: { type: DataTypes.DATE, field: 'updated_at', defaultValue: DataTypes.NOW },
  }, {
    tableName: 'bank_offers',
    timestamps: true,
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
  });

  BankOffer.associate = (models) => {
    BankOffer.belongsTo(models.User, { foreignKey: 'createdBy', as: 'creator' });
    BankOffer.belongsTo(models.User, { foreignKey: 'updatedBy', as: 'updater' });
    BankOffer.belongsToMany(models.Merchant, { through: 'bank_offer_applicable_merchants', as: 'applicableMerchants', foreignKey: 'bank_offer_id', otherKey: 'merchant_id', timestamps: false });
  };

  return BankOffer;
};
