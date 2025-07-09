const AdminLayout = ({ children }) => {
  const { Link } = ReactRouterDOM;

  // Basic styling for the admin layout
  const layoutStyle = {
    display: 'flex',
    minHeight: '100vh',
  };

  const sidebarStyle = {
    width: '250px',
    backgroundColor: '#f8f9fa', // A light gray background
    padding: '20px',
    borderRight: '1px solid #dee2e6', // A subtle border
  };

  const contentStyle = {
    flexGrow: 1,
    padding: '20px',
  };

  const navLinkStyle = {
    display: 'block',
    padding: '10px 15px',
    color: '#007bff', // Bootstrap primary blue
    textDecoration: 'none',
    borderRadius: '4px',
    marginBottom: '5px',
  };

  const activeNavLinkStyle = {
    ...navLinkStyle,
    backgroundColor: '#007bff',
    color: '#fff',
  };

  // Placeholder for active route detection - React Router's NavLink would handle this better
  const isActive = (path) => window.location.pathname === path;

  return (
    React.createElement('div', { style: layoutStyle },
      React.createElement('div', { style: sidebarStyle },
        React.createElement('h2', { className: 'text-xl font-bold mb-4' }, 'Admin Panel'),
        React.createElement('nav', null,
          React.createElement(Link, { to: '/admin/dashboard', style: isActive('/admin/dashboard') ? activeNavLinkStyle : navLinkStyle }, 'Dashboard'),
          React.createElement(Link, { to: '/admin/users', style: isActive('/admin/users') ? activeNavLinkStyle : navLinkStyle }, 'Users'),
          React.createElement(Link, { to: '/admin/merchants', style: isActive('/admin/merchants') ? activeNavLinkStyle : navLinkStyle }, 'Merchants'),
          React.createElement(Link, { to: '/admin/promotions', style: isActive('/admin/promotions') ? activeNavLinkStyle : navLinkStyle }, 'Promotions')
        )
      ),
      React.createElement('main', { style: contentStyle }, children)
    )
  );
};

window.AdminLayout = AdminLayout;
