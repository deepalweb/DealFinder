// Scripts for firebase and firebase messaging
importScripts('https://www.gstatic.com/firebasejs/8.2.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.2.0/firebase-messaging.js');

// Initialize the Firebase app in the service worker by passing in the messagingSenderId.
firebase.initializeApp({
    apiKey: "AIzaSyCIRMRjpSOtT8DzYW6EKmsdo4f2x14RR0k",
    authDomain: "dealfinder-d1a11.firebaseapp.com",
    projectId: "dealfinder-d1a11",
    storageBucket: "dealfinder-d1a11.firebasestorage.app",
    messagingSenderId: "735960530246",
    appId: "1:735960530246:web:443fde3bf85c0789ff3947",
    measurementId: "G-705W72GCRR"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/firebase-logo.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
