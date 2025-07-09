const AdminDashboardPage = () => {
  const { useState, useEffect, Fragment } = React;
  const { API } = window;
  const { Auth } = window;
  const { Link } = ReactRouterDOM;

  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchStats = async () => {
      if (!Auth.isAdmin()) {
        setError("Access denied. You must be an admin to view this page.");
        setLoading(false);
        return;
      }
      try {
        setLoading(true);
        const fetchedStats = await API.Admin.getDashboardStats();
        setStats(fetchedStats);
        setError(null);
      } catch (err) {
        console.error("Error fetching dashboard stats:", err);
        setError(err.message || "Failed to fetch dashboard statistics.");
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  const StatCard = ({ title, value, linkTo, details, icon }) => (
    React.createElement('div', { className: 'bg-white shadow-lg rounded-xl p-6 hover:shadow-2xl transition-shadow duration-300 flex flex-col justify-between' },
      React.createElement('div', null,
        React.createElement('div', { className: 'flex items-center justify-between mb-3' },
          React.createElement('h3', { className: 'text-lg font-semibold text-gray-600' }, title),
          icon && React.createElement('span', { className: 'text-3xl text-indigo-400' }, icon)
        ),
        React.createElement('p', { className: 'text-5xl font-bold text-indigo-600 mb-4' }, value),
        details && React.createElement('div', {className: 'text-sm text-gray-500 mb-4 space-y-1'},
          Object.entries(details).map(([key, val]) =>
            React.createElement('p', {key: key, className: 'flex justify-between'},
              React.createElement('span', null, `${key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}:`),
              React.createElement('span', {className: 'font-medium text-gray-600'}, val)
            )
          )
        )
      ),
      linkTo && React.createElement(Link, {
        to: linkTo,
        className: 'mt-auto block text-center bg-indigo-500 hover:bg-indigo-600 text-white font-semibold py-2 px-4 rounded-lg transition-colors duration-200'
      }, 'View Details')
    )
  );

  if (loading) {
    return React.createElement('div', { className: 'p-8 text-center text-gray-500' }, 'Loading dashboard data...');
  }

  if (error) {
    return React.createElement('div', { className: 'p-8 text-center text-red-600 bg-red-100 rounded-lg' },
      React.createElement('strong', null, 'Error: '), error
    );
  }

  if (!stats) {
    return React.createElement('div', { className: 'p-8 text-center text-gray-500' }, 'No dashboard data available.');
  }

  return (
    React.createElement(Fragment, null,
      React.createElement('h1', { className: 'text-4xl font-bold mb-10 text-gray-800' }, 'Admin Dashboard'),
      React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8' },
        React.createElement(StatCard, {
          title: 'Total Users',
          value: stats.totalUsers !== undefined ? stats.totalUsers : 'N/A',
          linkTo: '/admin/users',
          icon: '👤' // Unicode for user
        }),
        React.createElement(StatCard, {
          title: 'Total Merchants',
          value: stats.totalMerchants !== undefined ? stats.totalMerchants : 'N/A',
          linkTo: '/admin/merchants',
          details: stats.merchantsByStatus,
          icon: '🏪' // Unicode for store
        }),
        React.createElement(StatCard, {
          title: 'Total Promotions',
          value: stats.totalPromotions !== undefined ? stats.totalPromotions : 'N/A',
          linkTo: '/admin/promotions',
          details: stats.promotionsByStatus,
          icon: '🏷️' // Unicode for tag/label
        }),
        stats.merchantsByStatus && stats.merchantsByStatus.pending_approval !== undefined && stats.merchantsByStatus.pending_approval > 0 && React.createElement(StatCard, {
          title: 'Merchants Pending Approval',
          value: stats.merchantsByStatus.pending_approval,
          linkTo: '/admin/merchants?status=pending_approval', // Assuming filtering is implemented
          icon: '⏳' // Unicode for hourglass/pending
        }),
         stats.promotionsByStatus && stats.promotionsByStatus.pending_approval !== undefined && stats.promotionsByStatus.pending_approval > 0 && React.createElement(StatCard, {
          title: 'Promotions Pending Approval',
          value: stats.promotionsByStatus.pending_approval,
          linkTo: '/admin/promotions?status=pending_approval', // Assuming filtering is implemented
          icon: '⏳' // Unicode for hourglass/pending
        })
      )
    )
  );
};

window.AdminDashboardPage = AdminDashboardPage;
