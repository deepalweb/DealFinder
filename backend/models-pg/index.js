const { DataTypes } = require('sequelize');
const { getSequelize } = require('../services/postgres');

const sequelize = getSequelize();

const modelDefiners = [
  require('./Merchant'),
  require('./User'),
  require('./Promotion'),
  require('./BankOffer'),
  require('./DealAlert'),
  require('./NotificationLog'),
  require('./NotificationPreference'),
  require('./PromotionClick'),
  require('./Redemption'),
  require('./Report'),
  require('./SearchQueryLog'),
  require('./SectionAssignment'),
  require('./UserBehaviorEvent'),
  require('./UserPreferenceProfile'),
  require('./MerchantRating'),
  require('./MerchantReview'),
  require('./PromotionComment'),
  require('./PromotionRating'),
  require('./PromotionRedemptionFeedback'),
  require('./UserPreferenceCategory'),
];

const models = {};

if (sequelize) {
  for (const define of modelDefiners) {
    const model = define(sequelize, DataTypes);
    models[model.name] = model;
  }

  for (const model of Object.values(models)) {
    if (typeof model.associate === 'function') {
      model.associate(models);
    }
  }
}

module.exports = {
  sequelize,
  ...models,
};
