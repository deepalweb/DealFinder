import { ADMIN_STATUS_STYLES } from '@/lib/admin';

export default function AdminStatusChip({
  status,
  label,
}: {
  status?: string | null;
  label?: string;
}) {
  const resolvedStatus = status || 'default';
  const style = ADMIN_STATUS_STYLES[resolvedStatus] || {
    bg: 'var(--light-gray)',
    color: 'var(--text-secondary)',
  };

  return (
    <span
      className="status-chip"
      style={{
        background: style.bg,
        color: style.color,
      }}
    >
      {label || resolvedStatus.replace(/_/g, ' ')}
    </span>
  );
}
