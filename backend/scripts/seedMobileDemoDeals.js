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
  ['Bistro', 'food_dining', 'Colombo 03', [79.856, 6.914], 'photo-1414235077428-338989a2e8c0'],
  ['Bakery', 'food_dining', 'Colombo 04', [79.86, 6.898], 'photo-1509440159596-0249088772ff'],
  ['Spa', 'beauty_salon', 'Colombo 07', [79.867, 6.908], 'photo-1540555700478-4be289fbecef'],
  ['Bookshop', 'shopping_retail', 'Colombo 03', [79.859, 6.91], 'photo-1507842217343-583bb7270b66'],
  ['Fitness', 'health_wellness', 'Colombo 07', [79.871, 6.903], 'photo-1534438327276-14e5300c3a48'],
  ['Home Essentials', 'daily_essentials', 'Colombo 04', [79.862, 6.891], 'photo-1484154218962-a197022b5858'],
];
// [code suffix, shop index, title, regular price LKR, discount %, mode, expiry days, eligibility]
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
  ['BRUNCH', 6, '30% off weekend brunch', 5200, 30, 'visit', 21],
  ['BISTRO-CARD', 6, '25% off dinner with selected credit cards', 8000, 25, 'visit', 14,
    { bankName: 'Commercial Bank', cardTypes: ['credit'], offerType: 'dining', minimumSpend: 5000, maximumBenefit: 2500 }],
  ['BISTRO-TAKEAWAY', 6, '15% off takeaway lunch', 2400, 15, 'order', 7],
  ['BREAD', 7, '20% off artisan bread bundles', 1800, 20, 'hybrid', 10],
  ['CAKE', 7, '25% off celebration cakes', 6500, 25, 'order', 30],
  ['PASTRY-FLASH', 7, '40% off evening pastry boxes', 2200, 40, 'visit', 0],
  ['SPA-MASSAGE', 8, '30% off a relaxation massage', 9000, 30, 'visit', 21],
  ['SPA-CARD', 8, '20% off spa treatments with selected cards', 12000, 20, 'visit', 14,
    { bankName: 'HSBC', cardTypes: ['credit'], offerType: 'discount', minimumSpend: 8000, maximumBenefit: 3000 }],
  ['SPA-ENDING', 8, '35% off weekday wellness packages', 14000, 35, 'visit', 1],
  ['BOOKS', 9, '25% off fiction and reading bundles', 4500, 25, 'hybrid', 30],
  ['STATIONERY', 9, '20% off stationery packs', 2400, 20, 'hybrid', 7],
  ['BOOK-CARD', 9, '15% off books with selected debit cards', 6000, 15, 'hybrid', 21,
    { bankName: 'Sampath Bank', cardTypes: ['debit'], offerType: 'discount', minimumSpend: 3000, maximumBenefit: 1500 }],
  ['GYM', 10, '40% off a one-month gym pass', 10000, 40, 'visit', 14],
  ['PILATES', 10, '30% off introductory Pilates classes', 6000, 30, 'visit', 21],
  ['FITNESS-ENDING', 10, '50% off a personal training trial', 4000, 50, 'visit', 1],
  ['KITCHEN', 11, '25% off kitchen essentials', 8000, 25, 'hybrid', 30],
  ['HOME-CARD', 11, '20% off home essentials with selected cards', 15000, 20, 'hybrid', 14,
    { bankName: 'HNB', cardTypes: ['credit', 'debit'], offerType: 'discount', minimumSpend: 10000, maximumBenefit: 3000 }],
  ['HOME-DELIVERY', 11, '15% off storage and organizers', 5200, 15, 'order', 7],
  ['CAFE-CARD', 0, '20% off cafe meals with selected cards', 3500, 20, 'visit', 21,
    { bankName: 'Nations Trust Bank', cardTypes: ['credit'], offerType: 'dining', minimumSpend: 2500, maximumBenefit: 1000 }],
  ['TECH-CARD', 1, '15% off computer accessories with selected cards', 18000, 15, 'hybrid', 30,
    { bankName: 'Seylan Bank', cardTypes: ['credit'], offerType: 'electronics', minimumSpend: 10000, maximumBenefit: 5000 }],
  ['FASHION-ENDING', 2, '45% off selected casual wear - ending tonight', 8000, 45, 'visit', 0],
  ['GROCERY-FAMILY', 3, '20% off family grocery packs', 12000, 20, 'hybrid', 14],
  ['WELLNESS-CLASS', 4, '25% off guided stretching classes', 2400, 25, 'visit', 7],
  ['SALON-CARE', 5, '30% off hair care and styling', 6500, 30, 'visit', 21],
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
  const demoCodes = deals.map(([suffix]) => `DFDEV-${suffix}`);
  const before = await Promotion.countDocuments({ code: { $in: demoCodes } });
  const otherCount = await Promotion.countDocuments({ code: { $nin: demoCodes } });
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
        openingHours: Object.fromEntries(
          ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
            .map((weekday) => [weekday, { open: '08:00', close: '22:00', closed: false }]),
        ),
      } },
      { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true },
    ));
  }
  const promotions = [];
  for (const [suffix, shop, title, originalPrice, percent, mode, expires, eligibility = {}] of deals) {
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
        ...eligibility,
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
  if (await Promotion.countDocuments({ code: { $nin: demoCodes } }) !== otherCount) {
    throw new Error('Non-demo record count changed unexpectedly.');
  }
  console.log(`Added ${saved.length - before} new discounts; refreshed ${before} existing demo discounts.`);
  console.log(`Verified ${merchants.length} demo merchants and ${saved.length} discounts in test.`);
  console.log(`${saved.filter((p) => p.status === 'active').length} active, 1 scheduled, 1 expired; ${saved.filter((p) => p.bankName).length} bank/card offers. Five homepage assignments.`);
  console.log('Existing records preserved. Rerunning refreshes only these DFDEV discounts and DEMO stores.');
}

run().catch((error) => {
  console.error(`Demo seeding failed (${error.name}; code=${error.code || 'unavailable'}).`);
  process.exitCode = 1;
}).finally(() => mongoose.disconnect());
