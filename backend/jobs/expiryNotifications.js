const Promotion = require('../models/Promotion');
const User = require('../models/User');
const mailer = require('../mailer');

async function sendExpiryNotifications() {
  try {
    const now = new Date();
    const in3Days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    const in4Days = new Date(now.getTime() + 4 * 24 * 60 * 60 * 1000);

    // Deals expiring in next 3-4 days window (avoids duplicate sends)
    const expiringDeals = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      endDate: { $gte: in3Days, $lt: in4Days },
    }).populate('merchant');

    if (!expiringDeals.length) {
      console.log('[Expiry Notice] No deals expiring in 3 days.');
      return;
    }

    for (const deal of expiringDeals) {
      const merchantId = typeof deal.merchant === 'object' ? deal.merchant?._id : deal.merchant;
      if (!merchantId) continue;

      const merchantUser = await User.findOne({ merchantId, role: 'merchant' });
      if (!merchantUser?.email) continue;

      if (!process.env.M365_EMAIL) {
        console.log(`[Expiry Notice] Deal "${deal.title}" expires ${deal.endDate.toDateString()} — would notify: ${merchantUser.email}`);
        continue;
      }

      await mailer.sendMail({
        from: `"DealFinder" <${process.env.M365_EMAIL}>`,
        to: merchantUser.email,
        subject: `⏰ Your deal "${deal.title}" expires in 3 days`,
        html: `
          <div style="font-family:Inter,sans-serif;max-width:560px;margin:0 auto;padding:24px">
            <h2 style="color:#6366f1">Your deal is expiring soon!</h2>
            <p>Hi <strong>${merchantUser.name}</strong>,</p>
            <p>Your promotion <strong>"${deal.title}"</strong> with code
              <code style="background:#f1f5f9;padding:2px 8px;border-radius:4px">${deal.code}</code>
              will expire on <strong>${new Date(deal.endDate).toLocaleDateString('en-US', { weekday:'long', year:'numeric', month:'long', day:'numeric' })}</strong>.
            </p>
            <a href="${process.env.APP_URL || 'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net'}/merchant/dashboard"
              style="display:inline-block;background:linear-gradient(135deg,#6366f1,#4f46e5);color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;margin:16px 0">
              Renew or Create New Deal →
            </a>
            <p style="color:#64748b;font-size:14px">Log in to your merchant dashboard to extend this deal or create a new one.</p>
          </div>
        `,
      });

      console.log(`[Expiry Notice] Sent to ${merchantUser.email} for deal "${deal.title}"`);
    }
  } catch (err) {
    console.error('[Expiry Notice] Error:', err.message);
  }
}

module.exports = sendExpiryNotifications;
