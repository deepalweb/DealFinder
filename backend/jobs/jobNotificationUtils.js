const NotificationLog = require('../models/NotificationLog');

async function hasRecentNotification({
  userId,
  type,
  dealId,
  merchantId,
  category,
  summaryKey,
  since,
}) {
  const query = {
    userId,
    type,
    createdAt: { $gte: since },
  };

  if (dealId) {
    query['data.dealId'] = String(dealId);
  }

  if (merchantId) {
    query['data.merchantId'] = String(merchantId);
  }

  if (category) {
    query['data.category'] = String(category);
  }

  if (summaryKey) {
    query['data.summaryKey'] = String(summaryKey);
  }

  const existing = await NotificationLog.findOne(query).select('_id').lean();
  return Boolean(existing);
}

module.exports = {
  hasRecentNotification,
};
