'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import AdminStatusChip from '@/components/admin/AdminStatusChip';
import { BankOfferAPI } from '@/lib/api';
import toast from 'react-hot-toast';

type BankOfferRecord = {
  _id?: string;
  title?: string;
  discount?: string;
  bankName?: string;
  offerType?: string;
  cardTypes?: string[];
  status?: string;
  featured?: boolean;
  startDate?: string;
  endDate?: string;
};

export default function AdminBankOffersPage() {
  const router = useRouter();
  const [offers, setOffers] = useState<BankOfferRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    BankOfferAPI.getAdminAll()
      .then((data) => setOffers(Array.isArray(data) ? data : []))
      .catch(() => toast.error('Failed to load bank offers.'))
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    return offers.filter((offer) => {
      if (statusFilter !== 'all' && offer.status !== statusFilter) return false;
      if (!search.trim()) return true;
      const haystack = [
        offer.title,
        offer.bankName,
        offer.discount,
        offer.offerType,
        Array.isArray(offer.cardTypes) ? offer.cardTypes.join(' ') : '',
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(search.trim().toLowerCase());
    });
  }, [offers, search, statusFilter]);

  const updateStatus = async (offerId: string, status: string) => {
    try {
      const updated = await BankOfferAPI.update(offerId, { status });
      setOffers((prev) => prev.map((offer) => (offer._id === offerId ? updated : offer)));
      toast.success(`Bank offer ${status.replace(/_/g, ' ')}`);
    } catch (error: any) {
      toast.error(error.message || 'Failed to update bank offer.');
    }
  };

  const toggleFeatured = async (offer: BankOfferRecord) => {
    if (!offer._id) return;
    try {
      const updated = await BankOfferAPI.update(offer._id, { featured: !offer.featured });
      setOffers((prev) => prev.map((entry) => (entry._id === offer._id ? updated : entry)));
      toast.success(updated.featured ? 'Marked as featured' : 'Removed from featured');
    } catch (error: any) {
      toast.error(error.message || 'Failed to update bank offer.');
    }
  };

  const handleDelete = async (offer: BankOfferRecord) => {
    if (!offer._id) return;
    if (!confirm(`Delete "${offer.title || 'Untitled bank offer'}"? This cannot be undone.`)) return;
    try {
      await BankOfferAPI.delete(offer._id);
      setOffers((prev) => prev.filter((entry) => entry._id !== offer._id));
      toast.success('Bank offer deleted.');
    } catch (error: any) {
      toast.error(error.message || 'Failed to delete bank offer.');
    }
  };

  return (
    <div>
      <AdminPageHeader
        title="Bank Offers"
        subtitle={`${filtered.length} of ${offers.length} platform-managed bank offers`}
        actions={(
          <button className="btn btn-primary" onClick={() => router.push('/admin/bank-offers/new')}>
            <i className="fas fa-plus"></i> New Bank Offer
          </button>
        )}
      />

      <div className="toolbar-row" style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', marginBottom: '1rem' }}>
        <div className="input-with-icon toolbar-grow" style={{ maxWidth: '420px' }}>
          <i className="fas fa-search"></i>
          <input
            className="modern-input"
            placeholder="Search bank offers..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select className="modern-select" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="scheduled">Scheduled</option>
          <option value="draft">Draft</option>
          <option value="admin_paused">Paused</option>
          <option value="rejected">Rejected</option>
          <option value="expired">Expired</option>
        </select>
      </div>

      <div className="surface-panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table">
            <thead>
              <tr>
                {['Offer', 'Bank', 'Card Types', 'Status', 'Dates', 'Actions'].map((header) => (
                  <th key={header} style={{ textAlign: header === 'Actions' ? 'right' : 'left' }}>{header}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 5 }).map((_, index) => (
                  <tr key={index}>
                    <td colSpan={6} style={{ padding: '0.75rem 1rem' }}>
                      <div className="skeleton" style={{ height: '20px' }}></div>
                    </td>
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-secondary)' }}>
                    No bank offers found
                  </td>
                </tr>
              ) : (
                filtered.map((offer) => (
                  <tr key={offer._id}>
                    <td>
                      <div>
                        <p style={{ margin: 0, fontWeight: 700, color: 'var(--text-primary)' }}>{offer.title}</p>
                        <p style={{ margin: '0.2rem 0 0', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                          {offer.discount || '—'}
                          {offer.featured ? ' · Featured' : ''}
                        </p>
                      </div>
                    </td>
                    <td style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>{offer.bankName || '—'}</td>
                    <td style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                      {Array.isArray(offer.cardTypes) && offer.cardTypes.length
                        ? offer.cardTypes.map((type) => type.charAt(0).toUpperCase() + type.slice(1)).join(', ')
                        : '—'}
                    </td>
                    <td><AdminStatusChip status={(offer.status as any) || 'draft'} /></td>
                    <td style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                      {offer.startDate ? new Date(offer.startDate).toLocaleDateString() : '—'}
                      <br />
                      {offer.endDate ? new Date(offer.endDate).toLocaleDateString() : '—'}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="flex justify-end gap-2 flex-wrap">
                        <button
                          onClick={() => router.push(`/admin/bank-offers/new?edit=${offer._id}`)}
                          style={{ padding: '0.3rem 0.6rem', borderRadius: '0.5rem', border: '1.5px solid var(--border-color)', background: 'var(--card-bg)', color: 'var(--primary-color)', fontSize: '0.75rem', fontWeight: 600, cursor: 'pointer' }}
                        >
                          <i className="fas fa-edit"></i>
                        </button>
                        <button
                          onClick={() => updateStatus(offer._id!, offer.status === 'admin_paused' ? 'active' : 'admin_paused')}
                          style={{ padding: '0.3rem 0.6rem', borderRadius: '0.5rem', border: '1.5px solid rgba(100,116,139,0.3)', background: 'rgba(100,116,139,0.06)', color: '#64748b', fontSize: '0.75rem', fontWeight: 600, cursor: 'pointer' }}
                        >
                          <i className={`fas ${offer.status === 'admin_paused' ? 'fa-play' : 'fa-pause'}`}></i>
                        </button>
                        <button
                          onClick={() => toggleFeatured(offer)}
                          style={{ padding: '0.3rem 0.6rem', borderRadius: '0.5rem', border: `1.5px solid ${offer.featured ? 'rgba(245,158,11,0.3)' : 'var(--border-color)'}`, background: offer.featured ? 'rgba(245,158,11,0.08)' : 'var(--card-bg)', color: offer.featured ? '#d97706' : 'var(--text-secondary)', fontSize: '0.75rem', fontWeight: 600, cursor: 'pointer' }}
                        >
                          {offer.featured ? '⭐' : '☆'}
                        </button>
                        <button
                          onClick={() => handleDelete(offer)}
                          style={{ padding: '0.3rem 0.6rem', borderRadius: '0.5rem', border: '1.5px solid rgba(239,68,68,0.3)', background: 'rgba(239,68,68,0.06)', color: '#ef4444', fontSize: '0.75rem', fontWeight: 600, cursor: 'pointer' }}
                        >
                          <i className="fas fa-trash-alt"></i>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
