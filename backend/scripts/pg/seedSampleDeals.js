// Seeds sample merchants + promotions into Postgres for testing the new schema.
// Safe to re-run: uses fixed IDs and upserts (ON CONFLICT DO UPDATE).
require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const pg = require('../../models-pg');

const now = new Date();
const daysFromNow = (n) => new Date(now.getTime() + n * 24 * 60 * 60 * 1000);

const merchants = [
  {
    id: 'seed-merchant-1',
    name: 'Colombo Coffee Co.',
    category: 'Food & Beverage',
    merchantType: 'offline',
    status: 'active',
    currency: 'LKR',
    address: '42 Galle Road, Colombo 03',
    logo: 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=200&h=200&fit=crop',
    locationGeog: { type: 'Point', coordinates: [79.8500, 6.9147] },
  },
  {
    id: 'seed-merchant-2',
    name: 'Kandy Electronics Hub',
    category: 'Electronics',
    merchantType: 'hybrid',
    status: 'active',
    currency: 'LKR',
    address: '12 Peradeniya Road, Kandy',
    logo: 'https://images.unsplash.com/photo-1526406915894-7bcd65f60845?w=200&h=200&fit=crop',
    locationGeog: { type: 'Point', coordinates: [80.6337, 7.2906] },
  },
  {
    id: 'seed-merchant-3',
    name: 'Galle Fort Bookstore',
    category: 'Books & Stationery',
    merchantType: 'offline',
    status: 'active',
    currency: 'LKR',
    address: '5 Church Street, Galle Fort',
    logo: 'https://images.unsplash.com/photo-1521123845560-14093637aa7d?w=200&h=200&fit=crop',
    locationGeog: { type: 'Point', coordinates: [80.2170, 6.0269] },
  },
  {
    id: 'seed-merchant-4',
    name: 'TechZone Online',
    category: 'Electronics',
    merchantType: 'online',
    status: 'active',
    currency: 'LKR',
    website: 'https://techzone.example.lk',
    logo: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=200&h=200&fit=crop',
  },
];

const promotions = [
  {
    id: 'seed-deal-1',
    title: '20% Off All Espresso Drinks',
    description: 'Enjoy 20% off any espresso-based drink, all day every day this month.',
    discount: '20%',
    code: 'COFFEE20',
    category: 'Food & Beverage',
    merchantId: 'seed-merchant-1',
    startDate: daysFromNow(-2),
    endDate: daysFromNow(14),
    fulfillmentType: 'visit',
    status: 'active',
    featured: true,
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-2',
    title: 'Buy One Get One Free Pastries',
    description: 'Buy any pastry and get a second one free, weekdays before 10am.',
    discount: 'BOGO',
    code: 'PASTRYBOGO',
    category: 'Food & Beverage',
    merchantId: 'seed-merchant-1',
    startDate: daysFromNow(-1),
    endDate: daysFromNow(30),
    fulfillmentType: 'visit',
    status: 'active',
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-3',
    title: 'Rs. 15,000 Off Laptops',
    description: 'Flat Rs. 15,000 discount on all laptops over Rs. 150,000.',
    discount: 'Rs. 15,000',
    code: 'LAPTOP15K',
    category: 'Electronics',
    merchantId: 'seed-merchant-2',
    startDate: daysFromNow(-5),
    endDate: daysFromNow(10),
    fulfillmentType: 'hybrid',
    originalPrice: 175000,
    discountedPrice: 160000,
    status: 'active',
    featured: true,
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-4',
    title: '10% Cashback on Card Payments',
    description: 'Get 10% cashback when you pay with any Visa card, up to Rs. 5,000.',
    discount: '10% cashback',
    code: 'VISA10',
    category: 'Electronics',
    merchantId: 'seed-merchant-2',
    startDate: daysFromNow(0),
    endDate: daysFromNow(20),
    fulfillmentType: 'visit',
    bankName: 'Visa',
    cardTypes: ['credit', 'debit'],
    offerType: 'cashback',
    maximumBenefit: 5000,
    status: 'active',
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-5',
    title: '30% Off Travel Guidebooks',
    description: 'All Sri Lanka travel guidebooks discounted by 30% this week.',
    discount: '30%',
    code: 'TRAVEL30',
    category: 'Books & Stationery',
    merchantId: 'seed-merchant-3',
    startDate: daysFromNow(-3),
    endDate: daysFromNow(4),
    fulfillmentType: 'visit',
    status: 'active',
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1524578271613-d550eacf6090?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-6',
    title: 'Free Bookmark with Any Purchase',
    description: 'Get a free handcrafted bookmark with any purchase over Rs. 1,000.',
    discount: 'Free gift',
    code: 'FREEBOOKMARK',
    category: 'Books & Stationery',
    merchantId: 'seed-merchant-3',
    startDate: daysFromNow(0),
    endDate: daysFromNow(60),
    fulfillmentType: 'visit',
    status: 'scheduled',
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1526243741027-444d633d7365?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-7',
    title: 'Flash Sale: 40% Off Headphones',
    description: '24-hour flash sale on all wireless headphones.',
    discount: '40%',
    code: 'FLASH40',
    category: 'Electronics',
    merchantId: 'seed-merchant-4',
    startDate: daysFromNow(-0.2),
    endDate: daysFromNow(1),
    fulfillmentType: 'order',
    orderLink: 'https://techzone.example.lk/headphones-sale',
    deliveryAvailable: true,
    status: 'active',
    featured: true,
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&h=400&fit=crop',
  },
  {
    id: 'seed-deal-8',
    title: 'Free Shipping Over Rs. 5,000',
    description: 'Free island-wide shipping on all orders over Rs. 5,000.',
    discount: 'Free shipping',
    code: 'FREESHIP',
    category: 'Electronics',
    merchantId: 'seed-merchant-4',
    startDate: daysFromNow(-10),
    endDate: daysFromNow(45),
    fulfillmentType: 'order',
    orderLink: 'https://techzone.example.lk',
    deliveryAvailable: true,
    minimumSpend: 5000,
    status: 'active',
    adminVerified: true,
    image: 'https://images.unsplash.com/photo-1566576721346-d4a3b4eaeb55?w=600&h=400&fit=crop',
  },
];

async function run() {
  await pg.sequelize.authenticate();

  await pg.Merchant.bulkCreate(merchants, {
    updateOnDuplicate: Object.keys(merchants[0]).filter((k) => k !== 'id'),
  });
  console.log(`Seeded ${merchants.length} merchants.`);

  await pg.Promotion.bulkCreate(promotions, {
    updateOnDuplicate: [
      'title', 'description', 'discount', 'code', 'category', 'merchantId',
      'startDate', 'endDate', 'fulfillmentType', 'orderLink', 'deliveryAvailable',
      'featured', 'originalPrice', 'discountedPrice', 'bankName', 'cardTypes',
      'offerType', 'minimumSpend', 'maximumBenefit', 'status', 'adminVerified', 'image',
    ],
  });
  console.log(`Seeded ${promotions.length} promotions (deals).`);

  const merchantCount = await pg.Merchant.count();
  const promotionCount = await pg.Promotion.count();
  console.log(`\nTotals in Postgres now -> merchants: ${merchantCount}, promotions: ${promotionCount}`);

  await pg.sequelize.close();
}

run().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
