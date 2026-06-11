'use client';

import { useEffect, useMemo, useState } from 'react';
import AdminFilterBar from '@/components/admin/AdminFilterBar';
import AdminPageHeader from '@/components/admin/AdminPageHeader';
import AdminStatusChip from '@/components/admin/AdminStatusChip';
import { AdminAPI } from '@/lib/api';
import toast from 'react-hot-toast';

type ReportRecord = {
  _id: string;
  targetType: 'promotion' | 'merchant';
  reason: string;
  description?: string;
  status: 'open' | 'reviewing' | 'resolved' | 'dismissed';
  createdAt?: string;
  promotion?: { _id?: string; title?: string; status?: string; category?: string };
  merchant?: { _id?: string; name?: string; status?: string; category?: string };
  reporter?: { name?: string; email?: string };
  resolutionNote?: string;
};

const statusOptions = [
  { value: 'open', label: 'Open' },
  { value: 'reviewing', label: 'Reviewing' },
  { value: 'resolved', label: 'Resolved' },
  { value: 'dismissed', label: 'Dismissed' },
  { value: 'all', label: 'All' },
];

const targetOptions = [
  { value: 'all', label: 'All targets' },
  { value: 'promotion', label: 'Deals' },
  { value: 'merchant', label: 'Stores' },
];

function reasonLabel(reason: string) {
  return reason
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function reportTarget(report: ReportRecord) {
  if (report.targetType === 'promotion') return report.promotion?.title || 'Unknown deal';
  return report.merchant?.name || 'Unknown store';
}

export default function AdminReportsPage() {
  const [reports, setReports] = useState<ReportRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('open');
  const [targetType, setTargetType] = useState('all');
  const [search, setSearch] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);

  const loadReports = async () => {
    setLoading(true);
    try {
      const data = await AdminAPI.getReports({ status, targetType });
      setReports(Array.isArray(data) ? data : []);
    } catch {
      toast.error('Failed to load reports.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReports();
  }, [status, targetType]);

  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return reports;
    return reports.filter((report) =>
      [
        reportTarget(report),
        report.reason,
        report.description,
        report.reporter?.name,
        report.reporter?.email,
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(term))
    );
  }, [reports, search]);

  const updateReport = async (report: ReportRecord, nextStatus: ReportRecord['status']) => {
    setBusyId(report._id);
    try {
      await AdminAPI.updateReport(report._id, {
        status: nextStatus,
        resolutionNote:
          nextStatus === 'dismissed'
            ? 'Dismissed from admin report queue.'
            : nextStatus === 'resolved'
              ? 'Resolved from admin report queue.'
              : '',
      });
      toast.success(`Report marked ${nextStatus}.`);
      await loadReports();
    } catch {
      toast.error('Failed to update report.');
    } finally {
      setBusyId(null);
    }
  };

  const runReportAction = async (report: ReportRecord, action: string, label: string) => {
    setBusyId(report._id);
    try {
      await AdminAPI.runReportAction(report._id, action);
      toast.success(label);
      await loadReports();
    } catch {
      toast.error('Failed to run report action.');
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div>
      <AdminPageHeader
        title="Reports"
        subtitle="Review user-submitted deal and store reports."
        actions={
          <button className="btn-secondary" onClick={loadReports}>
            <i className="fas fa-sync" style={{ marginRight: '0.45rem' }}></i>
            Refresh
          </button>
        }
      />

      <AdminFilterBar>
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', alignItems: 'center' }}>
          <input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search reports, reporters, stores, deals..."
            className="form-input"
            style={{ minWidth: 280, flex: '1 1 280px' }}
          />
          <select className="form-input" value={status} onChange={(event) => setStatus(event.target.value)}>
            {statusOptions.map((option) => (
              <option key={option.value} value={option.value}>{option.label}</option>
            ))}
          </select>
          <select className="form-input" value={targetType} onChange={(event) => setTargetType(event.target.value)}>
            {targetOptions.map((option) => (
              <option key={option.value} value={option.value}>{option.label}</option>
            ))}
          </select>
        </div>
      </AdminFilterBar>

      <div className="surface-panel" style={{ overflow: 'hidden' }}>
        {loading ? (
          <div className="panel-pad">Loading reports...</div>
        ) : filtered.length === 0 ? (
          <div className="panel-pad" style={{ color: 'var(--text-secondary)' }}>
            No reports match the current filters.
          </div>
        ) : (
          <div style={{ display: 'grid', gap: 0 }}>
            {filtered.map((report) => (
              <div
                key={report._id}
                className="panel-pad"
                style={{
                  borderBottom: '1px solid var(--border-color)',
                  display: 'grid',
                  gridTemplateColumns: 'minmax(0, 1fr) auto',
                  gap: '1rem',
                  alignItems: 'start',
                }}
              >
                <div>
                  <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '0.45rem' }}>
                    <AdminStatusChip status={report.status} />
                    <span className="status-chip" style={{ background: '#eff6ff', color: '#1d4ed8' }}>
                      {report.targetType === 'promotion' ? 'Deal' : 'Store'}
                    </span>
                    <span className="status-chip" style={{ background: '#fff7ed', color: '#c2410c' }}>
                      {reasonLabel(report.reason)}
                    </span>
                  </div>
                  <h3 style={{ margin: '0 0 0.3rem', fontSize: '1rem', color: 'var(--text-primary)' }}>
                    {reportTarget(report)}
                  </h3>
                  <p style={{ margin: 0, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
                    {report.description || 'No details provided.'}
                  </p>
                  <p style={{ margin: '0.65rem 0 0', color: 'var(--text-tertiary)', fontSize: '0.78rem' }}>
                    Reported by {report.reporter?.name || report.reporter?.email || 'Unknown user'}
                    {report.createdAt ? ` • ${new Date(report.createdAt).toLocaleString()}` : ''}
                  </p>
                </div>
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
                  {report.targetType === 'promotion' && report.status !== 'resolved' && (
                    <>
                      <button
                        className="btn-secondary"
                        disabled={busyId === report._id}
                        onClick={() => runReportAction(report, 'pause_promotion', 'Promotion paused.')}
                      >
                        Pause deal
                      </button>
                      <button
                        className="btn-secondary"
                        disabled={busyId === report._id}
                        onClick={() => runReportAction(report, 'verify_promotion', 'Promotion verified.')}
                      >
                        Mark verified
                      </button>
                    </>
                  )}
                  {report.targetType === 'merchant' && report.status !== 'resolved' && (
                    <button
                      className="btn-secondary"
                      disabled={busyId === report._id}
                      onClick={() => runReportAction(report, 'suspend_merchant', 'Merchant suspended.')}
                    >
                      Suspend store
                    </button>
                  )}
                  {report.status === 'open' && (
                    <button
                      className="btn-secondary"
                      disabled={busyId === report._id}
                      onClick={() => updateReport(report, 'reviewing')}
                    >
                      Review
                    </button>
                  )}
                  {report.status !== 'resolved' && (
                    <button
                      className="btn-primary"
                      disabled={busyId === report._id}
                      onClick={() => updateReport(report, 'resolved')}
                    >
                      Resolve
                    </button>
                  )}
                  {report.status !== 'dismissed' && (
                    <button
                      className="btn-secondary"
                      disabled={busyId === report._id}
                      onClick={() => updateReport(report, 'dismissed')}
                    >
                      Dismiss
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
