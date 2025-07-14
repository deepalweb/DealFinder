const express = require('express');
const router = express.Router();
const webpush = require('web-push');
const User = require('../models/User');

// Subscribe Route
router.post('/subscribe', async (req, res) => {
    const { subscription, userId } = req.body;

    try {
        // Find the user by ID and update their push subscription
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        user.pushSubscription = subscription;
        user.preferences.notifications.push = true;
        await user.save();

        res.status(201).json({});

        // Send a test push notification
        const payload = JSON.stringify({ title: 'Push Notification Test' });
        webpush.sendNotification(subscription, payload).catch(err => console.error(err));

    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Notify Route
router.post('/notify', async (req, res) => {
    const { subscription, title, body, userId } = req.body;

    try {
        const user = await User.findById(userId);
        if (user && user.preferences.notifications.push) {
            const payload = JSON.stringify({ title, body });
            webpush.sendNotification(subscription, payload).catch(err => console.error(err));
        }
        res.status(200).json({});
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
