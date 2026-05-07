'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import { AdminAPI } from '@/lib/api';
import { formatAdminDate, getMerchantName } from '@/lib/admin';

type TrendPoint = {
  label: string;
  key: string;
  count: number;
};

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
        <div
          style={{
            width: '48px',
            height: '48px',
            borderRadius: '0.875rem',
            background: `${color}15`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '1.25rem',
          }}
        >
          <i className={`fas ${icon}`} style={{ color }}></i>
        </div>
        {href ? (
          <Link href={href} style={{ fontSize: '0.75rem', color: 'var(--primary-color)', fontWeight: 600, textDecoration: 'none' }}>
            View all →
          </Link>
        ) : null}
      </div>
      <div style={{ fontSize: '2.25rem', fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.03em', lineHeight: 1 }}>
        {loading ? '—' : value ?? 0}
      </div>
      <p style={{ fontSize: '0.875rem', color: 'var(--text-secondary)', margin: '0.4rem 0 0', fontWeight: 500 }}>{title}</p>
      {sub && !loading ? <p style={{ fontSize: '0.75rem', color, marginTop: '0.5rem', fontWeight: 600 }}>{sub}</p> : null}
    </div>
  );
}

function MiniTrendChart({
  title,
  icon,
  color,
  points,
  loading,
}: {
  title: string;
  icon: string;
  color: string;
  points: TrendPoint[];
  loading: boolean;
}) {
  const max = Math.max(...points.map((point) => point.count), 1);

  return (
    <div className="surface-panel panel-pad">
      <div className="flex items-center gap-2" style={{ marginBottom: '1rem' }}>
        <i className={`fas ${icon}`} style={{ color }}></i>
        <h3 style={{ margin: 0, fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)' }}>{title}</h3>
      </div>
      {loading ? (
        <div className="skeleton" style={{ height: '140px' }}></div>
      ) : (
        <>
          <div style={{ height: '140px', display: 'grid', gridTemplateColumns: `repeat(${points.length}, minmax(0, 1fr))`, gap: '0.45rem', alignItems: 'end' }}>
            {points.map((point) => (
              <div key={point.key} style={{ display: 'grid', gap: '0.35rem', justifyItems: 'center' }}>
                <div style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', fontWeight: 700 }}>{point.count}</div>
                <div
                  style={{
                    width: '100%',
                    minHeight: point.count > 0 ? '10px' : '4px',
                    height: `${Math.max((point.count / max) * 92, point.count > 0 ? 10 : 4)}px`,
                    borderRadius: '999px 999px 0 0',
                    background: `linear-gradient(180deg, ${color}, ${color}99)`,
                    boxShadow: `0 8px 18px ${color}22`,
                  }}
                ></div>
                <div style={{ fontSize: '0.68rem', color: 'var(--text-secondary)' }}>{point.label}</div>
              </div>
            ))}
          </div>
          <p style={{ margin: '0.85rem 0 0', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Last 14 days</p>
        </>
      )}
    </div>
  );
}

function AlertList({
  title,
  icon,
  color,
  empty,
  items,
  loading,
  actionHref,
  actionLabel,
  renderItem,
}: {
  title: string;
  icon: string;
  color: string;
  empty: string;
  items: any[];
  loading: boolean;
  actionHref?: string;
  actionLabel?: string;
  renderItem: (item: any) => React.ReactNode;
}) {
  return (
    <div className="surface-panel panel-pad">
      <div className="flex items-center justify-between gap-3" style={{ marginBottom: '1rem' }}>
        <div className="flex items-center gap-2">
          <i className={`fas ${icon}`} style={{ color }}></i>
          <h3 style={{ margin: 0, fontWeight: 800, fontSize: '1rem', color: 'var(--text-primary)' }}>{title}</h3>
        </div>
        {actionHref && actionLabel ? (
          <Link href={actionHref} style={{ fontSize: '0.75rem', color: color, fontWeight: 700, textDecoration: 'none' }}>
            {actionLabel}
          </Link>
        ) : null}
      </div>
      {loading ? (
        <div className="skeleton" style={{ height: '120px' }}></div>
      ) : items.length === 0 ? (
        <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', textAlign: 'center', padding: '1.2rem 0' }}>{empty}</div>
      ) : (
        <div style={{ display: 'grid', gap: '0.75rem' }}>{items.map(renderItem)}</div>
      )}
    </div>
  );
}

export default function AdminDashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [overview, setOverview] = useState<any>(null);
  const [trends, setTrends] = useState<any>(null);
  const [alerts, setAlerts] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [renderedAt] = useState(() => Date.now());

  useEffect(() => {
    Promise.all([
      AdminAPI.getDashboardStats(),
      AdminAPI.getDashboardOverview(),
      AdminAPI.getDashboardTrends(),
      AdminAPI.getDashboardAlerts(),
    ])
      .then(([statsData, overviewData, trendData, alertData]) => {
        setStats(statsData);
        setOverview(overviewData);
        setTrends(trendData);
        setAlerts(alertData);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const pendingMerchants = overview?.pending?.merchants || stats?.merchantsByStatus?.pending_approval || 0;
  const pendingPromotions = overview?.pending?.promotions || stats?.promotionsByStatus?.pending_approval || 0;

  const overviewCards = useMemo(
    () => [
      {
        title: 'Total Users',
        value: overview?.totals?.users ?? stats?.totalUsers,
        icon: 'fa-users',
        color: '#6366f1',
        href: '/admin/users',
        sub: overview?.thisWeek?.users ? `+${overview.thisWeek.users} this week` : undefined,
      },
      {
        title: 'Total Merchants',
        value: overview?.totals?.merchants ?? stats?.totalMerchants,
        icon: 'fa-store',
        color: '#10b981',
        href: '/admin/merchants',
        sub: pendingMerchants > 0 ? `${pendingMerchants} pending approval` : undefined,
      },
      {
        title: 'Total Promotions',
        value: overview?.totals?.promotions ?? stats?.totalPromotions,
        icon: 'fa-tags',
        color: '#f43f5e',
        href: '/admin/promotions',
        sub: overview?.thisWeek?.promotions ? `+${overview.thisWeek.promotions} this week` : undefined,
      },
      {
        title: 'Active Promotions',
        value: overview?.totals?.activePromotions ?? stats?.activePromotions,
        icon: 'fa-check-circle',
        color: '#10b981',
        sub: overview?.expiringToday ? `${overview.expiringToday} expiring today` : 'Live right now',
      },
      {
        title: 'Notification Delivery',
        value: `${overview?.notifications?.deliveryRate || 0}%`,
        icon: 'fa-paper-plane',
        color: '#8b5cf6',
        href: '/admin/notifications',
        sub: overview?.notifications?.total ? `${overview.notifications.total} sent this week` : undefined,
      },
      {
        title: 'Notification Open Rate',
        value: `${overview?.notifications?.openRate || 0}%`,
        icon: 'fa-envelope-open',
        color: '#f59e0b',
        href: '/admin/notifications',
        sub: overview?.notifications?.opened ? `${overview.notifications.opened} opened` : undefined,
      },
    ],
    [overview, pendingMerchants, stats]
  );

  const daysLeft = (date: string) => {
    const diff = new Date(date).getTime() - renderedAt;
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  return (
    <div>
      <AdminPageHeader
        title="Dashboard"
        subtitle="Marketplace health, growth trends, and admin alerts in one place."
        actions={
          <div
            style={{
              fontSize: '0.8rem',
              color: 'var(--text-secondary)',
              padding: '0.45rem 0.9rem',
              borderRadius: '9999px',
              background: 'rgba(255,255,255,0.7)',
              border: '1px solid rgba(148,163,184,0.2)',
            }}
          >
            <i className="fas fa-clock mr-1"></i>{' '}
            {new Date(renderedAt).toLocaleDateString('en-US', {
              weekday: 'long',
              month: 'long',
              day: 'numeric',
            })}
          </div>
        }
      />

      {(pendingMerchants > 0 || pendingPromotions > 0 || alerts?.brokenPromotions?.count > 0) && (
        <div
          className="surface-panel panel-pad"
          style={{
            marginBottom: '1.5rem',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            flexWrap: 'wrap',
            background: 'linear-gradient(135deg, rgba(245,158,11,0.1), rgba(249,115,22,0.08))',
            borderColor: 'rgba(245,158,11,0.25)',
          }}
        >
          <i className="fas fa-exclamation-triangle" style={{ color: '#f59e0b' }}></i>
          <span style={{ fontSize: '0.875rem', color: '#92400e', fontWeight: 500 }}>
            {pendingMerchants > 0 ? `${pendingMerchants} merchant approvals pending` : null}
            {pendingMerchants > 0 && pendingPromotions > 0 ? ' · ' : null}
            {pendingPromotions > 0 ? `${pendingPromotions} promotion approvals pending` : null}
            {(pendingMerchants > 0 || pendingPromotions > 0) && alerts?.brokenPromotions?.count > 0 ? ' · ' : null}
            {alerts?.brokenPromotions?.count > 0 ? `${alerts.brokenPromotions.count} promotions need content fixes` : null}
          </span>
          <div className="flex gap-2 ml-auto">
            {pendingMerchants > 0 ? (
              <Link href="/admin/merchants" style={{ fontSize: '0.75rem', fontWeight: 700, color: '#92400e', textDecoration: 'none', padding: '0.25rem 0.625rem', borderRadius: '0.375rem', background: 'rgba(245,158,11,0.15)' }}>
                Review Merchants
              </Link>
            ) : null}
            {pendingPromotions > 0 ? (
              <Link href="/admin/promotions" style={{ fontSize: '0.75rem', fontWeight: 700, color: '#92400e', textDecoration: 'none', padding: '0.25rem 0.625rem', borderRadius: '0.375rem', background: 'rgba(245,158,11,0.15)' }}>
                Review Promotions
              </Link>
            ) : null}
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5 mb-8">
        {overviewCards.map((card) => (
          <StatCard key={card.title} {...card} loading={loading} />
        ))}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-5 mb-8">
        <MiniTrendChart title="User Signups" icon="fa-user-plus" color="#6366f1" points={trends?.users || []} loading={loading} />
        <MiniTrendChart title="Promotions Created" icon="fa-tags" color="#f43f5e" points={trends?.promotions || []} loading={loading} />
        <MiniTrendChart title="Merchant Onboarding" icon="fa-store" color="#10b981" points={trends?.merchants || []} loading={loading} />
        <MiniTrendChart title="Notifications Sent" icon="fa-bell" color="#8b5cf6" points={trends?.notifications || []} loading={loading} />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-5 mb-8">
        <AlertList
          title="Content Issues"
          icon="fa-wand-magic-sparkles"
          color="#ef4444"
          loading={loading}
          items={alerts?.brokenPromotions?.items || []}
          actionHref="/admin/promotions"
          actionLabel="Open promotions"
          empty="No broken or incomplete promotions right now."
          renderItem={(item) => (
            <div key={item._id} style={{ padding: '0.75rem 0.85rem', borderRadius: '0.95rem', background: 'rgba(255,255,255,0.74)', border: '1px solid rgba(148,163,184,0.14)' }}>
              <div style={{ fontWeight: 700, color: 'var(--text-primary)', fontSize: '0.85rem' }}>{item.title}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '0.75rem', marginTop: '0.2rem' }}>
                {getMerchantName(item.merchant)} · {item.issue}
              </div>
            </div>
          )}
        />
        <AlertList
          title="Expiring Soon"
          icon="fa-fire"
          color="#f59e0b"
          loading={loading}
          items={alerts?.expiringSoon?.items || stats?.expiringSoon || []}
          actionHref="/admin/promotions"
          actionLabel="Open promotions"
          empty="No live promotions expiring soon."
          renderItem={(item) => {
            const days = item.endDate ? daysLeft(item.endDate) : null;
            return (
              <div key={item._id} style={{ padding: '0.75rem 0.85rem', borderRadius: '0.95rem', background: 'rgba(255,255,255,0.74)', border: '1px solid rgba(148,163,184,0.14)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '1rem' }}>
                <div>
                  <div style={{ fontWeight: 700, color: 'var(--text-primary)', fontSize: '0.85rem' }}>{item.title}</div>
                  <div style={{ color: 'var(--text-secondary)', fontSize: '0.75rem', marginTop: '0.2rem' }}>
                    {getMerchantName(item.merchant)} · Ends {formatAdminDate(item.endDate)}
                  </div>
                </div>
                <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#f59e0b', background: 'rgba(245,158,11,0.12)', padding: '0.2rem 0.5rem', borderRadius: '9999px', whiteSpace: 'nowrap' }}>
                  {days === 0 ? 'Today' : days === 1 ? 'Tomorrow' : `${days}d left`}
                </span>
              </div>
            );
          }}
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-8">
        <div className="surface-panel panel-pad">
          <h3 style={{ fontWeight: 700, fontSize: '1rem', color: 'var(--text-primary)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <i className="fas fa-tags" style={{ color: 'var(--primary-color)' }}></i> Promotions by Status
          </h3>
          {loading ? (
            <div className="skeleton" style={{ height: '120px' }}></div>
          ) : (
            <div className="flex flex-col gap-2">
              {(() => {
                const colors = {
                  active: '#10b981',
                  scheduled: '#6366f1',
                  pending_approval: '#f59e0b',
                  expired: '#94a3b8',
                  rejected: '#ef4444',
                  admin_paused: '#64748b',
                  draft: '#94a3b8',
                } as Record<string, string>;
                const entries = Object.entries(stats?.promotionsByStatus || {})
                  .filter(([, value]: any) => value > 0)
                  .sort(([, a]: any, [, b]: any) => b - a);
                return entries.length === 0 ? (
                  <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', textAlign: 'center', padding: '1rem 0' }}>No promotions yet</p>
                ) : (
                  entries.map(([status, count]: any) => (
                    <div key={status} className="flex items-center justify-between" style={{ padding: '0.6rem 0.8rem', borderRadius: '0.9rem', background: 'rgba(255,255,255,0.74)', border: '1px solid rgba(148,163,184,0.14)' }}>
                      <div className="flex items-center gap-2">
                        <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: colors[status] || '#94a3b8', flexShrink: 0 }}></div>
                        <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{status.replace(/_/g, ' ')}</span>
                      </div>
                      <span style={{ fontSize: '0.875rem', fontWeight: 700, color: colors[status] || 'var(--text-primary)' }}>{count}</span>
                    </div>
                  ))
                );
              })()}
            </div>
          )}
        </div>

        <AlertList
          title="Recent Activity"
          icon="fa-history"
          color="var(--primary-color)"
          loading={loading}
          items={stats?.activity || []}
          empty="No recent activity."
          renderItem={(item) => {
            const icons: Record<string, string> = { user: 'fa-user', merchant: 'fa-store', promotion: 'fa-tag' };
            const colors: Record<string, string> = { user: '#6366f1', merchant: '#10b981', promotion: '#f43f5e' };
            const color = colors[item.type] || '#94a3b8';
            const diff = renderedAt - new Date(item.time).getTime();
            const minutes = Math.floor(diff / 60000);
            const hours = Math.floor(minutes / 60);
            const days = Math.floor(hours / 24);
            const ago = days > 0 ? `${days}d ago` : hours > 0 ? `${hours}h ago` : minutes > 0 ? `${minutes}m ago` : 'just now';

            return (
              <div key={`${item.type}-${item.label}-${item.time}`} style={{ display: 'flex', alignItems: 'center', gap: '0.875rem', padding: '0.625rem 0.75rem', borderRadius: '0.5rem' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: `${color}15`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <i className={`fas ${icons[item.type]}`} style={{ color, fontSize: '0.75rem' }}></i>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ margin: 0, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.label}</p>
                  <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-secondary)', textTransform: 'capitalize' }}>{item.sub}</p>
                </div>
                <span style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', flexShrink: 0 }}>{ago}</span>
              </div>
            );
          }}
        />
      </div>
    </div>
  );
}
