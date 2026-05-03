'use client';

import { useEffect, useRef } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { NotificationAPI } from '@/lib/api';
import { buildApiUrl } from '@/lib/config/api';
import { checkNotificationPermission, syncWebPushSubscription } from '@/lib/webPush';

export default function WebPushBootstrap() {
  const { user } = useAuth();
  const initializedTokenRef = useRef<string | null>(null);

  useEffect(() => {
    if (!user?.token || initializedTokenRef.current === user.token) {
      return;
    }

    let isCancelled = false;

    const bootstrap = async () => {
      initializedTokenRef.current = user.token;

      try {
        const prefs = await NotificationAPI.getPreferences();
        if (!prefs?.channels?.web?.enabled) {
          return;
        }

        if (checkNotificationPermission() !== 'granted') {
          return;
        }

        const configResponse = await fetch(buildApiUrl('config'));
        const config = await configResponse.json();
        const vapidPublicKey = config?.VAPID_PUBLIC_KEY;

        if (!vapidPublicKey || isCancelled) {
          return;
        }

        await syncWebPushSubscription(user.token, vapidPublicKey);
      } catch (error) {
        console.warn('Web push bootstrap skipped:', error);
      }
    };

    const handleServiceWorkerMessage = async (event: MessageEvent) => {
      if (event.data?.type !== 'web-push-subscription-changed') {
        return;
      }

      try {
        const configResponse = await fetch(buildApiUrl('config'));
        const config = await configResponse.json();
        const vapidPublicKey = config?.VAPID_PUBLIC_KEY;
        if (!vapidPublicKey || isCancelled) {
          return;
        }

        await syncWebPushSubscription(user.token, vapidPublicKey);
      } catch (error) {
        console.warn('Failed to resync web push subscription:', error);
      }
    };

    bootstrap();
    navigator.serviceWorker?.addEventListener('message', handleServiceWorkerMessage);

    return () => {
      isCancelled = true;
      navigator.serviceWorker?.removeEventListener('message', handleServiceWorkerMessage);
    };
  }, [user?.token]);

  return null;
}
