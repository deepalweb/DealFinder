const test = require('node:test');
const assert = require('node:assert');

const sent = [];
const firebasePath = require.resolve('../services/firebaseAdmin');
require.cache[firebasePath] = {
  id: firebasePath,
  filename: firebasePath,
  loaded: true,
  exports: {
    admin: { apps: [{}], messaging: () => ({ send: async (message) => sent.push(message) }) },
    ensureFirebaseAdminInitialized: () => true,
  },
};
const NotificationService = require('../services/NotificationService');

test('push messages use the channel the mobile app creates', async () => {
  const log = { status: { push: {} } };
  const prefs = { channels: { push: { token: 'device-token' } } };

  await NotificationService._sendPushNotification(prefs, 'Title', 'Body', { dealId: 'deal-1', count: 2 }, log);

  assert.equal(log.status.push.error, undefined);
  assert.equal(sent[0].android.notification.channelId, 'dealfinder_general');
  assert.equal(sent[0].token, 'device-token');
  assert.deepEqual(sent[0].data, { dealId: 'deal-1', count: '2' });
});
