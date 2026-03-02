'use client';
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User } from '@/types';

interface AuthContextType {
  user: User | null;
  login: (user: User) => void;
  logout: () => void;
  isAdmin: () => boolean;
  isMerchant: () => boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const stored = localStorage.getItem('dealFinderUser');
    if (stored) setUser(JSON.parse(stored));
  }, []);

  const login = (user: User) => {
    localStorage.setItem('dealFinderUser', JSON.stringify(user));
    localStorage.setItem('dealFinderToken', user.token);
    setUser(user);
  };

  const logout = () => {
    localStorage.removeItem('dealFinderUser');
    localStorage.removeItem('dealFinderToken');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{
      user,
      login,
      logout,
      isAdmin: () => user?.role === 'admin',
      isMerchant: () => user?.role === 'merchant' || user?.role === 'admin',
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
};
