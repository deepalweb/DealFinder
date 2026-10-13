// Repeatable mobile development fixtures. Never deletes existing records.
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');
const SectionAssignment = require('../models/SectionAssignment');
const { getColomboDayRange } = require('../utils/promotionLifecycle');

const day = 24 * 60 * 60 * 1000;
const image = (id) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=1000&q=80`;
const shops = [
  ['Cafe', 'food_dining', 'Colombo 03', [79.854, 6.911], 'photo-1509042239860-f550ce710b93'],
  ['Electronics', 'electronics', 'Colombo 04', [79.858, 6.895], 'photo-1498049794561-7780e7231661'],
  ['Fashion', 'shopping_retail', 'Colombo 07', [79.869, 6.906], 'photo-1445205170230-053b83016050'],
  ['Grocery', 'daily_essentials', 'Nugegoda', [79.899, 6.865], 'photo-1542838132-92c53300491e'],
  ['Wellness', 'health_wellness', 'Rajagiriya', [79.894, 6.91], 'photo-1544367567-0f2fcb009e0b'],
  ['Salon', 'beauty_salon', 'Dehiwala', [79.865, 6.852], 'photo-1562322140-8baeececf3df'],
];
// [code suffix, shop index, title, regular price LKR, discount %, mode, expiry days]
const deals = [
  ['COFFEE', 0, '25% off coffee and cake', 1600, 25, 'visit', 30],
  ['LUNCH', 0, '20% off lunch for two', 4000, 20, 'hybrid', 14],
  ['HEADPHONES', 1, '30% off wireless headphones', 12000, 30, 'order', 30],
  ['SPEAKER', 1, '40% off portable speakers - flash sale', 10000, 40, 'hybrid', 0],
  ['FASHION', 2, '35% off casual wear', 6000, 35, 'visit', 21],
  ['GROCERY', 3, '15% off an essentials basket', 8000, 15, 'hybrid', 7],
  ['YOGA', 4, '50% off a beginner yoga session', 3000, 50, 'visit', 14],
  ['SALON', 5, '20% off a haircut package', 5000, 20, 'visit', 10],
  ['UPCOMING', 2, 'Upcoming weekend fashion sale', 5000, 25, 'visit', 10],
  ['EXPIRED', 0, 'Expired breakfast deal', 2000, 10, 'visit', -1],
];

async function run() {
  if (process.env.DATA_SOURCE !== 'mongo' || !process.env.MONGO_URI) {
    throw new Error('This script requires DATA_SOURCE=mongo and MONGO_URI.');
  }
  await mongoose.connect(process.env.MONGO_URI, {
    autoIndex: false, serverSelectionTimeoutMS: 15000,
  });
  if (mongoose.connection.name !== 'test') {
    throw new Error('Demo seeding is restricted to the test database.');
  }
  const { start } = getColomboDayRange();
  const merchants = [];
  for (const [name, category, address, coordinates, photo] of shops) {
    merchants.push(await Merchant.findOneAndUpdate(
      { name: `[DEMO] ${name}` },
      { $set: {
        name: `[DEMO] ${name}`, category, address: `Demo location, ${address}, Sri Lanka`,
        profile: 'Fictional store for mobile development. Offers are not redeemable.',
        description: 'Development sample merchant only.', contactInfo: 'demo@example.invalid',
        currency: 'LKR', status: 'active', merchantType: 'hybrid',
        deliveryAvailable: true, pickupAvailable: true,
        logo: image(photo), banner: image(photo),
        location: { type: 'Point', coordinates },
      } },
      { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true },
    ));
  }
  const promotions = [];
  for (const [suffix, shop, title, originalPrice, percent, mode, expires] of deals) {
    const status = suffix === 'UPCOMING' ? 'scheduled' : expires < 0 ? 'expired' : 'active';
    const startDate = new Date(start.getTime() + (status === 'scheduled' ? 3 : -2) * day);
    const endDate = new Date(start.getTime() + (expires + 1) * day - 1);
    const promotion = await Promotion.findOneAndUpdate(
      { code: `DFDEV-${suffix}` },
      { $set: {
        title: `[DEMO] ${title}`,
        description: 'Sample discount for mobile app development only. Not a real offer. Use this to test browsing, favorites, comparison, and deal details.',
        code: `DFDEV-${suffix}`, discount: `${percent}%`, category: shops[shop][1],
        merchant: merchants[shop]._id, originalPrice,
        discountedPrice: Math.round(originalPrice * (100 - percent) / 100),
        fulfillmentType: mode, visitAvailable: mode !== 'order',
        deliveryAvailable: mode !== 'visit', pickupAvailable: mode === 'hybrid',
        orderLink: mode !== 'visit' ? 'https://example.com/' : '',
        startDate, endDate, status, featured: ['COFFEE', 'HEADPHONES', 'FASHION'].includes(suffix),
        image: image(shops[shop][4]), images: [image(shops[shop][4])],
      } },
      { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true },
    );
    promotions.push(promotion);
    await Merchant.updateOne({ _id: merchants[shop]._id }, { $addToSet: { promotions: promotion._id } });
  }
  for (const [sectionKey, suffixes] of [
    ['banner', ['COFFEE', 'HEADPHONES', 'FASHION']],
    ['flash_sales', ['SPEAKER']],
    ['hot_deals', ['SPEAKER']],
  ]) {
    for (const [index, suffix] of suffixes.entries()) {
      const promotion = promotions.find((p) => p.code === `DFDEV-${suffix}`);
      await SectionAssignment.findOneAndUpdate(
        { sectionKey, promotion: promotion._id },
        { $set: { enabled: true, mode: 'manual', priority: 10 - index,
          startAt: promotion.startDate, endAt: promotion.endDate,
          bannerImageUrl: promotion.image, metadata: { demo: true } } },
        { upsert: true, runValidators: true, setDefaultsOnInsert: true },
      );
    }
  }
  const saved = await Promotion.find({ code: { $in: deals.map(([suffix]) => `DFDEV-${suffix}`) } })
    .populate('merchant', 'name currency location');
  if (saved.length !== deals.length || saved.some((p) => !p.merchant || p.merchant.currency !== 'LKR')) {
    throw new Error('Demo record verification failed.');
  }
  console.log(`Verified ${merchants.length} demo merchants and ${saved.length} discounts in test.`);
  console.log(`${saved.filter((p) => p.status === 'active').length} active, 1 scheduled, 1 expired. Five homepage assignments.`);
  console.log('Existing records preserved. Rerunning refreshes only these DFDEV discounts and DEMO stores.');
}

run().catch((error) => {
  console.error(`Demo seeding failed (${error.name}; code=${error.code || 'unavailable'}).`);
  process.exitCode = 1;
}).finally(() => mongoose.disconnect());
