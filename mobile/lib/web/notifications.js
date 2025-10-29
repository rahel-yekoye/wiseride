// Web notification support for Flutter

// Initialize Firebase (if using Firebase for web notifications)
// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.22.1/firebase-app.js";
import { getMessaging, getToken, onMessage } from "https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging.js";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "YOUR_FIREBASE_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

// Request permission for notifications
function requestNotificationPermission() {
  console.log('Requesting permission...');
  return new Promise((resolve, reject) => {
    if (!('Notification' in window)) {
      reject('This browser does not support desktop notification');
      return;
    }

    if (Notification.permission === 'granted') {
      resolve('granted');
      return;
    }

    if (Notification.permission === 'denied') {
      reject('permission-denied');
      return;
    }

    Notification.requestPermission().then((permission) => {
      if (permission === 'granted') {
        resolve('granted');
      } else {
        reject('permission-denied');
      }
    });
  });
}

// Get FCM token for the current device
async function getFCMToken() {
  try {
    const permission = await requestNotificationPermission();
    if (permission === 'granted') {
      const token = await getToken(messaging, {
        vapidKey: 'YOUR_VAPID_KEY'
      });
      return token;
    }
    return null;
  } catch (error) {
    console.error('Error getting FCM token:', error);
    return null;
  }
}

// Listen for incoming messages
onMessage(messaging, (payload) => {
  console.log('Message received:', payload);
  
  // Forward the message to Flutter
  if (window.flutter_inappwebview) {
    window.flutter_inappwebview.callHandler('handleNotification', payload);
  }
  
  // Show a notification
  if (Notification.permission === 'granted') {
    const notificationTitle = payload.notification?.title || 'New Notification';
    const notificationOptions = {
      body: payload.notification?.body || '',
      icon: payload.notification?.icon || '/favicon.ico',
      data: payload.data || {}
    };
    
    const notification = new Notification(notificationTitle, notificationOptions);
    
    notification.onclick = (event) => {
      event.preventDefault();
      // Handle notification click
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('notificationClicked', payload);
      }
      window.focus();
      notification.close();
    };
  }
});

// Export functions to be used in Flutter
window.NotificationUtils = {
  requestNotificationPermission,
  getFCMToken
};

// Initialize service worker for push notifications
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/firebase-messaging-sw.js')
      .then((registration) => {
        console.log('ServiceWorker registration successful');
      })
      .catch((err) => {
        console.error('ServiceWorker registration failed: ', err);
      });
  });
}
