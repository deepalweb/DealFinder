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

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    try {
      const stored = localStorage.getItem('dealFinderUser');
      if (stored) setUser(JSON.parse(stored));
    } catch {}
    setLoading(false);
  }, []);

  useEffect(() => {
    const handleStorage = (event: StorageEvent) => {
      if (event.key !== 'dealFinderUser') return;

      try {
        setUser(event.newValue ? JSON.parse(event.newValue) : null);
      } catch {
        setUser(null);
      }
    };

    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, []);

  const login = (userData: User) => {
    const normalized = { ...userData, merchantId: userData.merchantId?.toString() };
    localStorage.setItem('dealFinderUser', JSON.stringify(normalized));
    setUser(normalized);
  };

  const logout = async () => {
    try {
      await Promise.allSettled([
        NotificationAPI.unsubscribe('web'),
        unsubscribeFromPushNotifications(),
      ]);
    } catch {}

    localStorage.removeItem('dealFinderUser');
    invalidateCache();
    setUser(null);
    router.replace('/login');
    router.refresh();
  };

  const updateUser = (data: Partial<User>) => {
    if (!user) return;
    const updated = { ...user, ...data };
    localStorage.setItem('dealFinderUser', JSON.stringify(updated));
    setUser(updated);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
