'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';

export default function NotificationAnalyticsPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<any>(null);
  const [timeRange, setTimeRange] = useState('7d');

  useEffect(() => {
    if (!user || user.role !== 'admin') {
      router.push('/');
      return;
    }
    fetchAnalytics();
  }, [user, timeRange]);

  const fetchAnalytics = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('dealFinderUser');
      const parsedToken = token ? JSON.parse(token).token : null;

      const response = await fetch('/api/notifications/analytics/dashboard', {
        headers: {
          'Authorization': `Bearer ${parsedToken}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setStats(data);
      } else {
        toast.error('Failed to load analytics');
      }
    } catch (error) {
      toast.error('Error loading analytics');
    } finally {
      setLoading(false);
    }
  };

  if (!user || user.role !== 'admin') return null;

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div style={{ textAlign: 'center', padding: '4rem' }}>
          <i className="fas fa-spinner fa-spin" style={{ fontSize: '2rem', color: 'var(--primary-color)' }}></i>
          <p style={{ marginTop: '1rem', color: 'var(--text-secondary)' }}>Loading analytics...</p>
        </div>
      </div>
    );
  }

  const StatCard = ({ title, value, subtitle, icon, color }: any) => (
    <div
      style={{
        background: 'var(--card-bg)',
        border: '1.5px solid var(--border-color)',
        borderRadius: '1rem',
        padding: '1.5rem',
        display: 'flex',
        alignItems: 'center',
        gap: '1rem',
      }}
    >
      <div
        style={{
          width: '56px',
          height: '56px',
          borderRadius: '12px',
          background: `${color}15`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0,
        }}
      >
        <i className={`fas ${icon}`} style={{ fontSize: '1.5rem', color }}></i>
      </div>
      <div style={{ flex: 1 }}>
        <p style={{ margin: 0, fontSize: '0.875rem', color: 'var(--text-secondary)' }}>{title}</p>
        <h3 style={{ margin: '0.25rem 0', fontSize: '1.75rem', fontWeight: 800, color: 'var(--text-primary)' }}>
          {value}
        </h3>
        {subtitle && (
          <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-tertiary)' }}>{subtitle}</p>
        )}
      </div>
    </div>
  );

  const timeRangeData = timeRange === '24h' ? stats?.last24Hours : timeRange === '7d' ? stats?.last7Days : stats?.last30Days;

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>
            📊 Notification Analytics
          </h1>
          <p style={{ color: 'var(--text-secondary)' }}>Monitor notification performance and user engagement</p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {['24h', '7d', '30d'].map((range) => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              style={{
                padding: '0.5rem 1rem',
                borderRadius: '0.5rem',
                border: '1.5px solid var(--border-color)',
                background: timeRange === range ? 'var(--primary-color)' : 'var(--card-bg)',
                color: timeRange === range ? '#fff' : 'var(--text-primary)',
                cursor: 'pointer',
                fontWeight: 600,
                fontSize: '0.875rem',
              }}
            >
              {range === '24h' ? 'Last 24 Hours' : range === '7d' ? 'Last 7 Days' : 'Last 30 Days'}
            </button>
          ))}
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
        <StatCard
          title="Total Notifications"
          value={timeRangeData?.total?.toLocaleString() || '0'}
          icon="fa-bell"
          color="#6366f1"
        />
        <StatCard
          title="Delivery Rate"
          value={`${timeRangeData?.push?.deliveryRate || 0}%`}
          subtitle={`${timeRangeData?.push?.delivered || 0} delivered`}
          icon="fa-check-circle"
          color="#10b981"
        />
        <StatCard
          title="Open Rate"
          value={`${timeRangeData?.push?.openRate || 0}%`}
          subtitle={`${timeRangeData?.push?.opened || 0} opened`}
          icon="fa-envelope-open"
          color="#f59e0b"
        />
        <StatCard
          title="Read Rate"
          value={`${timeRangeData?.readRate || 0}%`}
          icon="fa-eye"
          color="#8b5cf6"
        />
      </div>

      <div style={{ marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-primary)' }}>
          By Notification Type
        </h2>
        <div style={{ background: 'var(--card-bg)', border: '1.5px solid var(--border-color)', borderRadius: '1rem', padding: '1.5rem' }}>
          {stats?.byType && stats.byType.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {stats.byType.map((type: any) => (
                <div key={type.type} style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                      <span style={{ fontWeight: 600, textTransform: 'capitalize' }}>
                        {type.type.replace(/_/g, ' ')}
                      </span>
                      <span style={{ color: 'var(--text-secondary)' }}>{type.count} sent</span>
                    </div>
                    <div style={{ height: '8px', background: 'var(--light-gray)', borderRadius: '4px', overflow: 'hidden' }}>
                      <div
                        style={{
                          height: '100%',
                          width: `${type.readRate}%`,
                          background: 'linear-gradient(90deg, #6366f1, #8b5cf6)',
                          transition: 'width 0.3s',
                        }}
                      />
                    </div>
                  </div>
                  <div style={{ minWidth: '60px', textAlign: 'right' }}>
                    <strong style={{ color: '#10b981' }}>{type.readRate}%</strong>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p style={{ textAlign: 'center', color: 'var(--text-secondary)', padding: '2rem' }}>
              No data available
            </p>
          )}
        </div>
      </div>

      {stats?.userEngagement && (
        <div style={{ marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-primary)' }}>
            User Engagement
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem' }}>
            <StatCard
              title="Total Users"
              value={stats.userEngagement.totalUsers.toLocaleString()}
              icon="fa-users"
              color="#6366f1"
            />
            <StatCard
              title="Active Users"
              value={stats.userEngagement.activeUsers.toLocaleString()}
              icon="fa-user-check"
              color="#10b981"
            />
            <StatCard
              title="Engaged Users"
              value={stats.userEngagement.engagedUsers.toLocaleString()}
              subtitle={`${stats.userEngagement.engagementRate}% engagement`}
              icon="fa-heart"
              color="#ec4899"
            />
            <StatCard
              title="Push Opt-in"
              value={`${stats.userEngagement.optInRates.push}%`}
              icon="fa-bell"
              color="#f59e0b"
            />
          </div>
        </div>
      )}
    </div>
  );
}
