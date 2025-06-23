const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Notification = require('../models/Notification');
const transporter = require('../mailer');
const { authenticateJWT, authorizeAdmin } = require('../middleware/auth');

// Add safeError helper
function safeError(error) {
  if (process.env.NODE_ENV === 'production') {
    return { message: 'An error occurred' };
  }
  return { message: error.message, stack: error.stack };
}

// Get all notifications (Admin only)
router.get('/', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const notifications = await Notification.find();
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Create a new notification (Admin only - for a specific user)
router.post('/', authenticateJWT, authorizeAdmin, [
  body('userId').trim().notEmpty().withMessage('User ID is required'), // Admin specifies which user to notify
  body('message').trim().notEmpty().withMessage('Message is required'),
  body('type').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  const { userId, message, type } = req.body;
  try {
    // TODO: Optionally, check if userId exists before creating notification
    const newNotification = new Notification({ userId, message, type });
    await newNotification.save();
    res.status(201).json(newNotification);
  } catch (error) {
    res.status(500).json(safeError(error));
  }
});

// Test route to send a notification email (Admin only)
router.post('/test-email', authenticateJWT, authorizeAdmin, async (req, res) => {
  try {
    const { to, subject, text } = req.body;
    if (!to || !subject || !text) {
      return res.status(400).json({ message: 'Missing required fields: to, subject, text' });
    }
    await transporter.sendMail({
      from: `DealFinder <${process.env.M365_EMAIL}>`,
      to,
      subject: subject || 'DealFinder Test Email',
      text: text || 'This is a test notification from DealFinder.',
      html: `<p>${text || 'This is a test notification from DealFinder.'}</p>`
    });
    res.status(200).json({ message: 'Test email sent successfully.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to send test email.', error: err.message });
  }
});

module.exports = router;