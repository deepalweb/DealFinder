'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { NotificationAPI } from '@/lib/api';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';

interface Notification {
  _id: string;
  type: string;
  title: string;
  body: string;
  data: any;
  read: boolean;
  createdAt: string;
}

export default function NotificationsPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'unread'>('all');

  useEffect(() => {
    if (!user) {
      router.push('/login');
      return;
    }
    fetchNotifications();
  }, [user, filter]);

  const fetchNotifications = async () => {
    setLoading(true);
    try {
      const data = await NotificationAPI.getAll({ 
        limit: 50, 
        unreadOnly: filter === 'unread' 
      });
      setNotifications(data);
    } catch (error) {
      toast.error('Failed to load notifications');
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (id: string) => {
    try {
      await NotificationAPI.markAsRead(id);
      setNotifications(prev =>
        prev.map(n => n._id === id ? { ...n, read: true } : n)
      );
    } catch (error) {
      toast.error('Failed to mark as read');
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await NotificationAPI.delete(id);
      setNotifications(prev => prev.filter(n => n._id !== id));
      toast.success('Notification deleted');
    } catch (error) {
      toast.error('Failed to delete notification');
    }
  };

  const handleNotificationClick = (notification: Notification) => {
    if (!notification.read) {
      handleMarkAsRead(notification._id);
    }
    if (notification.data?.dealId) {
      router.push(`/deal/${notification.data.dealId}`);
    }
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  };

  const getNotificationIcon = (type: string) => {
    const icons: Record<string, { icon: string; color: string }> = {
      nearby_deal: { icon: 'fa-map-marker-alt', color: '#10b981' },
      favorite_store: { icon: 'fa-heart', color: '#ec4899' },
      expiring_deal: { icon: 'fa-clock', color: '#f59e0b' },
      price_drop: { icon: 'fa-tag', color: '#ef4444' },
      flash_sale: { icon: 'fa-bolt', color: '#8b5cf6' },
      category_deal: { icon: 'fa-th-large', color: '#6366f1' },
      deal_redeemed: { icon: 'fa-check-circle', color: '#10b981' },
      account_activity: { icon: 'fa-user', color: '#64748b' },
    };
    return icons[type] || { icon: 'fa-bell', color: '#6366f1' };
  };

  if (!user) return null;

  return (
    <div className="page-shell compact">
      <div className="page-header">
        <div>
          <div className="page-eyebrow"><i className="fas fa-bell"></i> Notifications</div>
          <h1 className="page-title">Stay on top of what matters.</h1>
          <p className="page-subtitle">Your latest alerts, deal changes, and account activity all in one place.</p>
        </div>
      </div>

      <div className="glass-toolbar" style={{ marginBottom: '1.5rem', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            onClick={() => setFilter('all')}
            style={{
              padding: '0.5rem 1rem',
              borderRadius: '9999px',
              border: '1px solid rgba(148, 163, 184, 0.2)',
              background: filter === 'all' ? 'var(--primary-gradient)' : 'rgba(255,255,255,0.7)',
              color: filter === 'all' ? '#fff' : 'var(--text-primary)',
              cursor: 'pointer',
              fontWeight: 600,
              fontSize: '0.875rem',
            }}
          >
            All
          </button>
          <button
            onClick={() => setFilter('unread')}
            style={{
              padding: '0.5rem 1rem',
              borderRadius: '9999px',
              border: '1px solid rgba(148, 163, 184, 0.2)',
              background: filter === 'unread' ? 'var(--primary-gradient)' : 'rgba(255,255,255,0.7)',
              color: filter === 'unread' ? '#fff' : 'var(--text-primary)',
              cursor: 'pointer',
              fontWeight: 600,
              fontSize: '0.875rem',
            }}
          >
            Unread
          </button>
        </div>

        <button
          onClick={() => router.push('/profile')}
          style={{
            padding: '0.5rem 1rem',
            borderRadius: '9999px',
            border: '1px solid rgba(148, 163, 184, 0.2)',
            background: 'rgba(255,255,255,0.75)',
            color: 'var(--primary-color)',
            cursor: 'pointer',
            fontWeight: 600,
            fontSize: '0.875rem',
          }}
        >
          <i className="fas fa-cog mr-2"></i>
          Settings
        </button>
      </div>

      {loading ? (
        <div className="surface-panel panel-pad" style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
          <i className="fas fa-spinner fa-spin" style={{ fontSize: '2rem', marginBottom: '1rem' }}></i>
          <p>Loading notifications...</p>
        </div>
      ) : notifications.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon"><i className="fas fa-bell-slash"></i></div>
          <h3 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.5rem', color: 'var(--text-primary)' }}>
            {filter === 'unread' ? 'No unread notifications' : 'No notifications yet'}
          </h3>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '1.5rem' }}>
            {filter === 'unread' ? 'You\'re all caught up!' : 'We\'ll notify you when something interesting happens'}
          </p>
          <button
            onClick={() => router.push('/')}
            className="btn btn-primary"
          >
            <i className="fas fa-home mr-2"></i>
            Go to Home
          </button>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {notifications.map(notification => {
            const { icon, color } = getNotificationIcon(notification.type);
            return (
              <div
                key={notification._id}
                className="surface-panel"
                style={{
                  padding: '1.25rem',
                  display: 'flex',
                  gap: '1rem',
                  alignItems: 'start',
                  transition: 'all 0.2s',
                  borderColor: notification.read ? 'var(--border-color)' : 'rgba(37, 99, 235, 0.35)',
                }}
              >
                <div
                  style={{
                    width: '48px',
                    height: '48px',
                    borderRadius: '50%',
                    background: `${color}15`,
                    color: color,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                    fontSize: '1.25rem',
                  }}
                >
                  <i className={`fas ${icon}`}></i>
                </div>

                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '0.5rem' }}>
                    <h3
                      onClick={() => handleNotificationClick(notification)}
                      style={{
                        fontSize: '1rem',
                        fontWeight: 700,
                        color: 'var(--text-primary)',
                        margin: 0,
                        cursor: notification.data?.dealId ? 'pointer' : 'default',
                      }}
                    >
                      {notification.title}
                    </h3>
                    {!notification.read && (
                      <div
                        style={{
                          width: '10px',
                          height: '10px',
                          borderRadius: '50%',
                          background: 'var(--primary-color)',
                          flexShrink: 0,
                          marginLeft: '0.5rem',
                        }}
                      />
                    )}
                  </div>

                  <p
                    style={{
                      fontSize: '0.9rem',
                      color: 'var(--text-secondary)',
                      margin: '0 0 0.75rem',
                      lineHeight: 1.5,
                    }}
                  >
                    {notification.body}
                  </p>

                  <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
                    <span style={{ fontSize: '0.8rem', color: 'var(--text-tertiary)' }}>
                      <i className="fas fa-clock mr-1"></i>
                      {formatTime(notification.createdAt)}
                    </span>

                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      {!notification.read && (
                        <button
                          onClick={() => handleMarkAsRead(notification._id)}
                          style={{
                            padding: '0.25rem 0.75rem',
                            fontSize: '0.75rem',
                            borderRadius: '0.375rem',
                            border: 'none',
                            background: 'var(--primary-color)',
                            color: '#fff',
                            cursor: 'pointer',
                            fontWeight: 600,
                          }}
                        >
                          Mark as read
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(notification._id)}
                        style={{
                          padding: '0.25rem 0.75rem',
                          fontSize: '0.75rem',
                          borderRadius: '0.375rem',
                          border: '1px solid var(--border-color)',
                          background: 'transparent',
                          color: '#ef4444',
                          cursor: 'pointer',
                          fontWeight: 600,
                        }}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
