'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminAPI } from '@/lib/api';

export default function AdminDashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    AdminAPI.getDashboardStats().then(setStats).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const StatCard = ({ title, value, icon, color, href, sub }: any) => (
    <div className="promotion-card" style={{ padding:'1.5rem' }}>
      <div className="flex items-center justify-between mb-3">
        <div style={{ width:'48px', height:'48px', borderRadius:'0.875rem', background:`${color}15`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:'1.25rem' }}>
          <i className={`fas ${icon}`} style={{ color }}></i>
        </div>
        {href && <Link href={href} style={{ fontSize:'0.75rem', color:'var(--primary-color)', fontWeight:600, textDecoration:'none' }}>View all →</Link>}
      </div>
      <div style={{ fontSize:'2.25rem', fontWeight:800, color:'var(--text-primary)', letterSpacing:'-0.03em', lineHeight:1 }}>{loading ? '—' : (value ?? 'N/A')}</div>
      <p style={{ fontSize:'0.875rem', color:'var(--text-secondary)', margin:'0.4rem 0 0', fontWeight:500 }}>{title}</p>
      {sub && !loading && <p style={{ fontSize:'0.75rem', color, marginTop:'0.5rem', fontWeight:600 }}>{sub}</p>}
    </div>
  );

  const pendingMerchants = stats?.merchantsByStatus?.pending_approval || 0;
  const pendingPromotions = stats?.promotionsByStatus?.pending_approval || 0;

  return (
    <div>
      <div className="flex items-center justify-between mb-8 flex-wrap gap-3">
        <div>
          <h1 style={{ fontSize:'1.75rem', fontWeight:800, color:'var(--text-primary)', margin:0, letterSpacing:'-0.02em' }}>Dashboard</h1>
          <p style={{ color:'var(--text-secondary)', margin:0, fontSize:'0.875rem' }}>Welcome back! Here&apos;s what&apos;s happening.</p>
        </div>
        <div style={{ fontSize:'0.8rem', color:'var(--text-secondary)', padding:'0.4rem 0.875rem', borderRadius:'9999px', background:'var(--light-gray)', border:'1px solid var(--border-color)' }}>
          <i className="fas fa-clock mr-1"></i> {new Date().toLocaleDateString('en-US', { weekday:'long', month:'long', day:'numeric' })}
        </div>
      </div>

      {/* Alerts */}
      {(pendingMerchants > 0 || pendingPromotions > 0) && (
        <div style={{ padding:'1rem 1.25rem', borderRadius:'0.875rem', background:'rgba(245,158,11,0.08)', border:'1px solid rgba(245,158,11,0.25)', marginBottom:'1.5rem', display:'flex', alignItems:'center', gap:'0.75rem', flexWrap:'wrap' }}>
          <i className="fas fa-exclamation-triangle" style={{ color:'#f59e0b' }}></i>
          <span style={{ fontSize:'0.875rem', color:'#92400e', fontWeight:500 }}>
            {pendingMerchants > 0 && `${pendingMerchants} merchant${pendingMerchants>1?'s':''} pending approval`}
            {pendingMerchants > 0 && pendingPromotions > 0 && ' · '}
            {pendingPromotions > 0 && `${pendingPromotions} promotion${pendingPromotions>1?'s':''} pending approval`}
          </span>
          <div className="flex gap-2 ml-auto">
            {pendingMerchants > 0 && <Link href="/admin/merchants" style={{ fontSize:'0.75rem', fontWeight:700, color:'#92400e', textDecoration:'none', padding:'0.25rem 0.625rem', borderRadius:'0.375rem', background:'rgba(245,158,11,0.15)' }}>Review Merchants</Link>}
            {pendingPromotions > 0 && <Link href="/admin/promotions" style={{ fontSize:'0.75rem', fontWeight:700, color:'#92400e', textDecoration:'none', padding:'0.25rem 0.625rem', borderRadius:'0.375rem', background:'rgba(245,158,11,0.15)' }}>Review Promotions</Link>}
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
        <StatCard title="Total Users" value={stats?.totalUsers} icon="fa-users" color="#6366f1" href="/admin/users" />
        <StatCard title="Total Merchants" value={stats?.totalMerchants} icon="fa-store" color="#10b981" href="/admin/merchants" sub={pendingMerchants > 0 ? `${pendingMerchants} pending approval` : undefined} />
        <StatCard title="Total Promotions" value={stats?.totalPromotions} icon="fa-tags" color="#f43f5e" href="/admin/promotions" sub={pendingPromotions > 0 ? `${pendingPromotions} pending approval` : undefined} />
        <StatCard title="Active Promotions" value={stats?.promotionsByStatus?.active} icon="fa-check-circle" color="#f59e0b" />
      </div>

      {/* Breakdown */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {/* Merchants by status */}
        <div className="promotion-card" style={{ padding:'1.5rem' }}>
          <h3 style={{ fontWeight:700, fontSize:'1rem', color:'var(--text-primary)', marginBottom:'1rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
            <i className="fas fa-store" style={{ color:'var(--primary-color)' }}></i> Merchants by Status
          </h3>
          {loading ? <div className="skeleton" style={{ height:'120px' }}></div> : (
            <div className="flex flex-col gap-2">
              {stats?.merchantsByStatus && Object.entries(stats.merchantsByStatus).map(([status, count]: any) => (
                <div key={status} className="flex items-center justify-between" style={{ padding:'0.5rem 0.75rem', borderRadius:'0.5rem', background:'var(--light-gray)' }}>
                  <span style={{ fontSize:'0.85rem', color:'var(--text-secondary)', textTransform:'capitalize' }}>{status.replace(/_/g,' ')}</span>
                  <span style={{ fontSize:'0.875rem', fontWeight:700, color:'var(--text-primary)' }}>{count}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Promotions by status */}
        <div className="promotion-card" style={{ padding:'1.5rem' }}>
          <h3 style={{ fontWeight:700, fontSize:'1rem', color:'var(--text-primary)', marginBottom:'1rem', display:'flex', alignItems:'center', gap:'0.5rem' }}>
            <i className="fas fa-tags" style={{ color:'var(--primary-color)' }}></i> Promotions by Status
          </h3>
          {loading ? <div className="skeleton" style={{ height:'120px' }}></div> : (
            <div className="flex flex-col gap-2">
              {stats?.promotionsByStatus && Object.entries(stats.promotionsByStatus).map(([status, count]: any) => (
                <div key={status} className="flex items-center justify-between" style={{ padding:'0.5rem 0.75rem', borderRadius:'0.5rem', background:'var(--light-gray)' }}>
                  <span style={{ fontSize:'0.85rem', color:'var(--text-secondary)', textTransform:'capitalize' }}>{status.replace(/_/g,' ')}</span>
                  <span style={{ fontSize:'0.875rem', fontWeight:700, color:'var(--text-primary)' }}>{count}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
