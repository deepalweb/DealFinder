'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { invalidateCache, NotificationAPI } from '@/lib/api';
import { unsubscribeFromPushNotifications } from '@/lib/webPush';

interface User {
  _id: string;
  name: string;
  email: string;
  role: 'user' | 'merchant' | 'admin';
  merchantId?: string;
  profilePicture?: string;
  token: string;
  refreshToken?: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (userData: User) => void;
  logout: () => Promise<void>;
  updateUser: (data: Partial<User>) => void;
}

const AuthContext = createContext<AuthContextType>({
  user: null, loading: true,
  login: () => {}, logout: async () => {}, updateUser: () => {}
});

const withTimeout = async <T,>(promise: Promise<T>, ms: number): Promise<T | null> => {
  return Promise.race([
    promise,
    new Promise<null>((resolve) => {
      window.setTimeout(() => resolve(null), ms);
    }),
  ]);
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    try {
      const stored = localStorage.getItem('dealFinderUser');
      setUser(stored ? JSON.parse(stored) as User : null);
    } catch {
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const handleStorage = (event: StorageEvent) => {
      if (event.key !== 'dealFinderUser') return;

      try {
        setUser(event.newValue ? JSON.parse(event.newValue) : null);
      } catch {
        setUser(null);
      } finally {
        setLoading(false);
      }
    };

    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, []);

  const login = (userData: User) => {
    const normalized = { ...userData, merchantId: userData.merchantId?.toString() };
    localStorage.setItem('dealFinderUser', JSON.stringify(normalized));
    setUser(normalized);
    setLoading(false);
  };

  const logout = async () => {
    void (async () => {
      try {
        await Promise.allSettled([
          withTimeout(NotificationAPI.unsubscribe('web'), 1500),
          withTimeout(unsubscribeFromPushNotifications(), 1500),
        ]);
      } catch {}
    })();

    localStorage.removeItem('dealFinderUser');
    invalidateCache();
    setUser(null);
    setLoading(false);
    router.replace('/login');
    router.refresh();
  };

  const updateUser = (data: Partial<User>) => {
    if (!user) return;
    const updated = { ...user, ...data };
    localStorage.setItem('dealFinderUser', JSON.stringify(updated));
    setUser(updated);
    setLoading(false);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
