'use client';
import Link from 'next/link';
import { useAuth } from '@/lib/auth-context';
import { useState } from 'react';

export default function Header() {
  const { user, logout } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="bg-indigo-600 text-white shadow-md">
      <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
        <Link href="/" className="text-xl font-bold tracking-tight">DealFinder</Link>

        <nav className="hidden md:flex items-center gap-6 text-sm font-medium">
          <Link href="/" className="hover:text-indigo-200">Home</Link>
          <Link href="/categories" className="hover:text-indigo-200">Categories</Link>
          <Link href="/merchants" className="hover:text-indigo-200">Merchants</Link>
        </nav>

        <div className="flex items-center gap-3 text-sm">
          {user ? (
            <>
              {user.role === 'merchant' && (
                <Link href="/merchant/dashboard" className="hover:text-indigo-200">Dashboard</Link>
              )}
              {user.role === 'admin' && (
                <Link href="/admin/dashboard" className="hover:text-indigo-200">Admin</Link>
              )}
              <button onClick={logout} className="bg-white text-indigo-600 px-3 py-1 rounded font-semibold hover:bg-indigo-50">
                Logout
              </button>
            </>
          ) : (
            <>
              <Link href="/login" className="hover:text-indigo-200">Login</Link>
              <Link href="/register" className="bg-white text-indigo-600 px-3 py-1 rounded font-semibold hover:bg-indigo-50">
                Sign Up
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
