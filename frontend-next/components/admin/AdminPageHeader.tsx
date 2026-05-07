type AdminPageHeaderProps = {
  title: string;
  subtitle: string;
  actions?: React.ReactNode;
};

export default function AdminPageHeader({ title, subtitle, actions }: AdminPageHeaderProps) {
  return (
    <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
      <div>
        <h1
          style={{
            fontSize: '1.75rem',
            fontWeight: 800,
            color: 'var(--text-primary)',
            margin: 0,
            letterSpacing: '-0.02em',
          }}
        >
          {title}
        </h1>
        <p style={{ color: 'var(--text-secondary)', margin: 0, fontSize: '0.875rem' }}>{subtitle}</p>
      </div>
      {actions}
    </div>
  );
}
