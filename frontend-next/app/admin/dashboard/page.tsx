'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminAPI } from '@/lib/api';

function StatCard({
  title,
  value,
  icon,
  color,
  href,
  sub,
  loading,
}: {
  title: string;
  value: number | string | undefined;
  icon: string;
  color: string;
  href?: string;
  sub?: string;
  loading: boolean;
}) {
  return (
    <div className="promotion-card" style={{ padding: '1.5rem' }}>
      <div className="flex items-center justify-between mb-3">
        <div style={{ width: '48px', height: '48px', borderRadius: '0.875rem', background: `${color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.25rem' }}>
          <i className={`fas ${icon}`} style={{ color }}></i>
        </div>
        {href && <Link href={href} style={{ fontSize: '0.75rem', color: 'var(--primary-color)', fontWeight: 600, textDecoration: 'none' }}>View all →</Link>}
      </div>
      <div style={{ fontSize: '2.25rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.03em', lineHeight: 1 }}>
        {loading ? '—' : (value ?? 0)}
      </div>
      <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', margin: '0.4rem 0 0', fontWeight: 500 }}>{title}</p>
      {sub && !loading && <p style={{ fontSize: '0.75rem', color, marginTop: '0.5rem', fontWeight: 600 }}>{sub}</p>}
    </div>
  );
}

export default function AdminDashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [renderedAt] = useState(() => Date.now());

  useEffect(() => {
    AdminAPI.getDashboardStats().then(setStats).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const pendingMerchants = stats?.merchantsByStatus?.pending_approval || 0;
  const pendingPromotions = stats?.promotionsByStatus?.pending_approval || 0;

  const daysLeft = (date: string) => {
    const diff = new Date(date).getTime() - renderedAt;
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-8 flex-wrap gap-3">
        <div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.02em' }}>Dashboard</h1>
          <p style={{ color: 'var(--text-secondary)', margin: 0, fontSize: '0.875rem' }}>Welcome back! Here&apos;s what&apos;s happening.</p>
        </div>
        <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', padding: '0.45rem 0.9rem', borderRadius: '9999px', background: 'rgba(255,255,255,0.7)', border: '1px solid rgba(148,163,184,0.2)' }}>
          <i className="fas fa-clock mr-1"></i> {new Date(renderedAt).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
        </div>
      </div>

      {/* Alerts */}
      {(pendingMerchants > 0 || pendingPromotions > 0) && (
        <div className="surface-panel panel-pad" style={{ marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap', background: 'linear-gradient(135deg, rgba(245,158,11,0.1), rgba(249,115,22,0.08))', borderColor: 'rgba(245,158,11,0.25)' }}>
          <i className="fas fa-exclamation-triangle" style={{ color: '#f59e0b' }}></i>
          <span style={{ fontSize: '0.875rem', color: '#92400e', fontWeight: 500 }}>
            {pendingMerchants > 0 && `${pendingMerchants} merchant${pendingMerchants > 1 ? 's' : ''} pending approval`}
            {pendingMerchants > 0 && pendingPromotions > 0 && ' · '}
            {pendingPromotions > 0 && `${pendingPromotions} promotion${pendingPromotions > 1 ? 's' : ''} pending approval`}
          </span>
          <div className="flex gap-2 ml-auto">
            {pendingMerchants > 0 && <Link href="/admin/merchants" style={{ fontSize: '0.75rem', fontWeight: 700, color: '#92400e', textDecoration: 'none', padding: '0.25rem 0.625rem', borderRadius: '0.375rem', background: 'rgba(245,158,11,0.15)' }}>Review Merchants</Link>}
            {pendingPromotions > 0 && <Link href="/admin/promotions" style={{ fontSize: '0.75rem', fontWeight: 700, color: '#92400e', textDecoration: 'none', padding: '0.25rem 0.625rem', borderRadius: '0.375rem', background: 'rgba(245,158,11,0.15)' }}>Review Promotions</Link>}
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
        <StatCard title="Total Users" value={stats?.totalUsers} icon="fa-users" color="#6366f1" href="/admin/users" loading={loading} />
        <StatCard title="Total Merchants" value={stats?.totalMerchants} icon="fa-store" color="#10b981" href="/admin/merchants" sub={pendingMerchants > 0 ? `${pendingMerchants} pending approval` : undefined} loading={loading} />
        <StatCard title="Total Promotions" value={stats?.totalPromotions} icon="fa-tags" color="#f43f5e" href="/admin/promotions" sub={pendingPromotions > 0 ? `${pendingPromotions} pending approval` : undefined} loading={loading} />
        <StatCard title="Active Promotions" value={stats?.activePromotions} icon="fa-check-circle" color="#10b981"
          sub={stats?.activePromotions > 0 ? 'Live & within date range' : 'No active deals right now'} loading={loading} />
      </div>

      {/* Bottom row */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {/* Promotions by status */}
        <div className="surface-panel panel-pad">
          <h3 style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-primary)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <i className="fas fa-tags" style={{ color: 'var(--primary-color)' }}></i> Promotions by Status
          </h3>
          {loading ? <div className="skeleton" style={{ height: '120px' }}></div> : (
            <div className="flex flex-col gap-2">
              {(() => {
                const colors: Record<string, string> = { active: '#10b981', scheduled: '#6366f1', pending_approval: '#f59e0b', expired: '#94a3b8', rejected: '#ef4444', admin_paused: '#64748b', draft: '#94a3b8' };
                const entries = Object.entries(stats?.promotionsByStatus || {}).filter(([, v]: any) => v > 0).sort(([, a]: any, [, b]: any) => b - a);
                return entries.length === 0
                  ? <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', textAlign: 'center', padding: '1rem 0' }}>No promotions yet</p>
                  : entries.map(([status, count]: any) => (
                    <div key={status} className="flex items-center justify-between" style={{ padding: '0.6rem 0.8rem', borderRadius: '0.9rem', background: 'rgba(255,255,255,0.74)', border: '1px solid rgba(148,163,184,0.14)' }}>
                      <div className="flex items-center gap-2">
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: colors[status] || '#94a3b8', flexShrink: 0 }}></div>
                        <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{status.replace(/_/g, ' ')}</span>
                      </div>
                      <span style={{ fontSize: '0.875rem', fontWeight: 700, color: colors[status] || 'var(--text-primary)' }}>{count}</span>
                    </div>
                  ));
              })()}
            </div>
          )}
        </div>

        {/* Expiring Soon */}
        <div className="surface-panel panel-pad">
          <h3 style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-primary)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <i className="fas fa-fire" style={{ color: '#ef4444' }}></i> Expiring This Week
            {!loading && stats?.expiringSoon?.length > 0 && (
              <span style={{ marginLeft: 'auto', fontSize: '0.72rem', fontWeight: 700, color: '#ef4444', background: 'rgba(239,68,68,0.1)', padding: '0.2rem 0.5rem', borderRadius: '9999px' }}>
                {stats.expiringSoon.length} deal{stats.expiringSoon.length > 1 ? 's' : ''}
              </span>
            )}
          </h3>
          {loading ? <div className="skeleton" style={{ height: '120px' }}></div> : (
            stats?.expiringSoon?.length > 0 ? (
              <div className="flex flex-col gap-2">
                {stats.expiringSoon.map((p: any) => {
                  const days = daysLeft(p.endDate);
                  const urgent = days <= 1;
                  const warn = days <= 3;
                  const color = urgent ? '#ef4444' : warn ? '#f59e0b' : '#6366f1';
                  return (
                    <div key={p._id} style={{ padding: '0.7rem 0.8rem', borderRadius: '0.95rem', background: 'rgba(255,255,255,0.74)', border: '1px solid rgba(148,163,184,0.14)', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <div style={{ flexShrink: 0, width: '36px', height: '36px', borderRadius: '0.5rem', background: `${color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <i className="fas fa-clock" style={{ color, fontSize: '0.85rem' }}></i>
                      </div>
                      <div style={{ minWidth: 0, flex: 1 }}>
                        <p style={{ margin: 0, fontSize: '0.82rem', fontWeight: 600, color: 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.title}</p>
                        <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{typeof p.merchant === 'object' ? p.merchant?.name : p.merchant}</p>
                      </div>
                      <span style={{ flexShrink: 0, fontSize: '0.72rem', fontWeight: 700, color, background: `${color}15`, padding: '0.2rem 0.5rem', borderRadius: '9999px', whiteSpace: 'nowrap' }}>
                        {days === 0 ? 'Today' : days === 1 ? 'Tomorrow' : `${days}d left`}
                      </span>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div style={{ textAlign: 'center', padding: '2rem 0', color: 'var(--text-secondary)', fontSize: '0.875rem' }}>
                <i className="fas fa-check-circle" style={{ fontSize: '1.5rem', color: '#10b981', marginBottom: '0.5rem', display: 'block' }}></i>
                No deals expiring this week
              </div>
            )
          )}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="surface-panel panel-pad" style={{ marginTop: '1.25rem' }}>
        <h3 style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-primary)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <i className="fas fa-history" style={{ color: 'var(--primary-color)' }}></i> Recent Activity
        </h3>
        {loading ? <div className="skeleton" style={{ height: '200px' }}></div> : (
          <div className="flex flex-col gap-1">
            {(!stats?.activity || stats.activity.length === 0) ? (
              <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', textAlign: 'center', padding: '1.5rem 0' }}>No recent activity</p>
            ) : stats.activity.map((item: any, i: number) => {
              const icons: Record<string, string> = { user: 'fa-user', merchant: 'fa-store', promotion: 'fa-tag' };
              const colors: Record<string, string> = { user: '#6366f1', merchant: '#10b981', promotion: '#f43f5e' };
              const color = colors[item.type] || '#94a3b8';
              const timeAgo = (date: string) => {
                const diff = renderedAt - new Date(date).getTime();
                const m = Math.floor(diff / 60000);
                const h = Math.floor(m / 60);
                const d = Math.floor(h / 24);
                if (d > 0) return `${d}d ago`;
                if (h > 0) return `${h}h ago`;
                if (m > 0) return `${m}m ago`;
                return 'just now';
              };
              return (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.875rem', padding: '0.625rem 0.75rem', borderRadius: '0.5rem', transition: 'background 0.15s' }}
                  onMouseEnter={e => (e.currentTarget.style.background = 'var(--light-gray)')}
                  onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: `${color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <i className={`fas ${icons[item.type]}`} style={{ color, fontSize: '0.75rem' }}></i>
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ margin: 0, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.label}</p>
                    <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{item.sub}</p>
                  </div>
                  <span style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', flexShrink: 0 }}>{timeAgo(item.time)}</span>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
