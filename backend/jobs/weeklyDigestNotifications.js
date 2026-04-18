const Promotion = require('../models/Promotion');
const User = require('../models/User');
const NotificationPreference = require('../models/NotificationPreference');
const NotificationService = require('../services/NotificationService');
const mailer = require('../mailer');

/**
 * Send weekly digest emails with top deals
 * Run this job every Sunday at 8 AM
 */
async function sendWeeklyDigest() {
  try {
    console.log('[Weekly Digest Job] Starting...');

    // Get users with weekly digest enabled
    const preferences = await NotificationPreference.find({
      'preferences.weeklyDigest.enabled': true,
      'channels.email.enabled': true
    }).populate('userId');

    if (preferences.length === 0) {
      console.log('[Weekly Digest Job] No users with weekly digest enabled');
      return;
    }

    console.log(`[Weekly Digest Job] Sending digest to ${preferences.length} users`);

    // Get top deals from the last week
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const topDeals = await Promotion.find({
      status: { $in: ['active', 'approved'] },
      createdAt: { $gte: oneWeekAgo },
      endDate: { $gte: new Date() }
    })
    .populate('merchant')
    .sort({ createdAt: -1 })
    .limit(10);

    if (topDeals.length === 0) {
      console.log('[Weekly Digest Job] No deals to include in digest');
      return;
    }

    let emailsSent = 0;

    for (const pref of preferences) {
      const user = pref.userId;
      if (!user || !user.email) continue;

      try {
        // Filter deals by user's preferred categories if any
        let userDeals = topDeals;
        if (pref.preferences.categories && pref.preferences.categories.length > 0) {
          userDeals = topDeals.filter(deal => 
            pref.preferences.categories.includes(deal.category)
          );
        }

        if (userDeals.length === 0) {
          userDeals = topDeals.slice(0, 5); // Fallback to top 5 deals
        }

        const emailHtml = generateDigestEmail(user.name, userDeals);

        await mailer.sendMail({
          from: `DealFinder <${process.env.M365_EMAIL}>`,
          to: user.email,
          subject: `🎉 Your Weekly Deal Digest - ${userDeals.length} Hot Deals!`,
          html: emailHtml
        });

        // Log the notification
        await NotificationService.sendNotification(
          user._id,
          'weekly_digest',
          { dealCount: userDeals.length },
          {
            title: 'Weekly Digest Sent',
            body: `Your weekly digest with ${userDeals.length} deals has been sent to your email`,
            channels: ['email'],
            priority: 'low'
          }
        );

        emailsSent++;
      } catch (error) {
        console.error(`[Weekly Digest Job] Failed to send to ${user.email}:`, error.message);
      }
    }

    console.log(`[Weekly Digest Job] Sent ${emailsSent} digest emails`);
  } catch (error) {
    console.error('[Weekly Digest Job] Error:', error.message);
  }
}

/**
 * Generate HTML email for weekly digest
 */
function generateDigestEmail(userName, deals) {
  const appUrl = process.env.APP_URL || 'https://dealfinderlk.com';
  
  const dealsHtml = deals.map(deal => {
    const merchantName = typeof deal.merchant === 'object' ? deal.merchant.name : 'Store';
    const imageUrl = deal.image || 'https://placehold.co/400x200?text=Deal&bg=f3f4f6&textcolor=6b7280';
    const dealUrl = `${appUrl}/deal/${deal._id}`;
    
    return `
      <tr>
        <td style="padding: 16px;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
            <tr>
              <td>
                <img src="${imageUrl}" alt="${deal.title}" style="width: 100%; height: 200px; object-fit: cover; display: block;" />
              </td>
            </tr>
            <tr>
              <td style="padding: 20px;">
                <h3 style="margin: 0 0 8px; font-size: 18px; color: #1e293b;">${deal.title}</h3>
                <p style="margin: 0 0 12px; color: #64748b; font-size: 14px;">
                  <strong style="color: #6366f1;">${merchantName}</strong>
                </p>
                <div style="display: inline-block; background: linear-gradient(135deg, #6366f1, #8b5cf6); color: #fff; padding: 8px 16px; border-radius: 8px; font-weight: 700; font-size: 16px; margin-bottom: 12px;">
                  ${deal.discount || 'Special Offer'}
                </div>
                <p style="margin: 0 0 16px; color: #475569; font-size: 14px; line-height: 1.6;">
                  ${deal.description.substring(0, 120)}${deal.description.length > 120 ? '...' : ''}
                </p>
                <a href="${dealUrl}" style="display: inline-block; background: #6366f1; color: #fff; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600;">
                  View Deal →
                </a>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    `;
  }).join('');

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Weekly Deal Digest</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: Inter, Arial, sans-serif; background: #f8fafc;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background: #f8fafc; padding: 40px 20px;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" style="max-width: 600px;">
              <!-- Header -->
              <tr>
                <td style="text-align: center; padding-bottom: 32px;">
                  <h1 style="color: #6366f1; margin: 0 0 8px; font-size: 32px; font-weight: 900;">
                    🎉 DealFinder
                  </h1>
                  <p style="color: #64748b; margin: 0; font-size: 16px;">
                    Your Weekly Deal Digest
                  </p>
                </td>
              </tr>
              
              <!-- Greeting -->
              <tr>
                <td style="background: #fff; border-radius: 12px; padding: 24px; margin-bottom: 24px;">
                  <h2 style="margin: 0 0 12px; font-size: 24px; color: #1e293b;">
                    Hi ${userName}! 👋
                  </h2>
                  <p style="margin: 0; color: #475569; font-size: 16px; line-height: 1.6;">
                    Here are the <strong>${deals.length} hottest deals</strong> from this week that we think you'll love!
                  </p>
                </td>
              </tr>
              
              <!-- Deals -->
              ${dealsHtml}
              
              <!-- CTA -->
              <tr>
                <td style="padding: 32px 16px; text-align: center;">
                  <a href="${appUrl}" style="display: inline-block; background: linear-gradient(135deg, #6366f1, #8b5cf6); color: #fff; padding: 16px 32px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);">
                    Browse All Deals →
                  </a>
                </td>
              </tr>
              
              <!-- Footer -->
              <tr>
                <td style="padding: 24px; text-align: center; border-top: 1px solid #e2e8f0;">
                  <p style="margin: 0 0 8px; color: #94a3b8; font-size: 14px;">
                    You're receiving this because you subscribed to weekly digests.
                  </p>
                  <p style="margin: 0; color: #94a3b8; font-size: 14px;">
                    <a href="${appUrl}/profile" style="color: #6366f1; text-decoration: none;">Manage preferences</a> | 
                    <a href="${appUrl}/unsubscribe" style="color: #6366f1; text-decoration: none;">Unsubscribe</a>
                  </p>
                  <p style="margin: 16px 0 0; color: #cbd5e1; font-size: 12px;">
                    © ${new Date().getFullYear()} DealFinder. All rights reserved.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;
}

module.exports = sendWeeklyDigest;
