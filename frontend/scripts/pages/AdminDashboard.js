// AdminDashboard.js
function AdminDashboard() {
  const { useState, useEffect } = React;
  const { Link, useNavigate } = ReactRouterDOM;

  const [summary, setSummary] = useState(null);
  const [usersOverTimeData, setUsersOverTimeData] = useState(null);
  const [promotionsByCategoryData, setPromotionsByCategoryData] = useState(null);
  const [loading, setLoading] = useState(true); // For initial summary
  const [chartsLoading, setChartsLoading] = useState(true); // For chart data
  const [error, setError] = useState('');
  const [chartsError, setChartsError] = useState('');
  const [currentView, setCurrentView] = useState('dashboard');

  const navigate = useNavigate();

  // Ensure 'UserManagement', 'MerchantManagement', 'PromotionManagement' are globally available or imported
  // For now, we'll assume they will be created and made available similar to other page components.
  // If using ES6 modules, they would be imported:
  // import UserManagement from '../components/admin/UserManagement';
  // import MerchantManagement from '../components/admin/MerchantManagement';
  // import PromotionManagement from '../components/admin/PromotionManagement';

  const UserManagement = window.UserManagement;
  const MerchantManagement = window.MerchantManagement;
  const PromotionManagement = window.PromotionManagement;


  useEffect(() => {
    const user = JSON.parse(localStorage.getItem('dealFinderUser'));
    if (!user || user.role !== 'admin') {
      navigate('/login'); // Redirect if not admin
      return;
    }

    const fetchAdminData = async () => {
      try {
        setLoading(true); // For summary
        setChartsLoading(true); // For charts
        setError('');
        setChartsError('');

        if (!window.API || !window.API.Admin) {
          throw new Error("Admin API helper not available.");
        }

        // Fetch summary
        if (window.API.Admin.getSummary) {
          const summaryData = await window.API.Admin.getSummary();
          setSummary(summaryData);
        } else {
          throw new Error("getSummary API method not found.");
        }
        setLoading(false); // Summary loaded or failed

        // Fetch chart data concurrently
        let usersData = null;
        if (window.API.Admin.getUsersOverTime) {
          usersData = await window.API.Admin.getUsersOverTime();
          setUsersOverTimeData(usersData);
        } else {
          setChartsError(prev => prev + ' getUsersOverTime API method not found.');
        }

        let categoriesData = null;
        if (window.API.Admin.getPromotionsByCategory) {
          categoriesData = await window.API.Admin.getPromotionsByCategory();
          setPromotionsByCategoryData(categoriesData);
        } else {
          setChartsError(prev => prev + ' getPromotionsByCategory API method not found.');
        }

      } catch (e) {
        console.error("Failed to fetch admin data:", e);
        const errorMessage = 'Failed to load admin data. ' + e.message;
        if (loading) setError(errorMessage); // Error happened during summary fetch
        setChartsError(prev => prev + ' ' + errorMessage);
      } finally {
        setLoading(false); // Ensure summary loading is always stopped
        setChartsLoading(false); // Charts attempt finished
      }
    };

    fetchAdminData();
  }, [navigate]);

  // Effect for Users Over Time Chart
  useEffect(() => {
    let chartInstance = null;
    if (usersOverTimeData && document.getElementById('usersOverTimeChart')) {
      const ctx = document.getElementById('usersOverTimeChart').getContext('2d');
      chartInstance = new Chart(ctx, {
        type: 'line',
        data: {
          labels: usersOverTimeData.map(d => d.date),
          datasets: [{
            label: 'New Users',
            data: usersOverTimeData.map(d => d.count),
            borderColor: 'rgb(99, 102, 241)',
            backgroundColor: 'rgba(99, 102, 241, 0.5)',
            tension: 0.1
          }]
        },
        options: {
          responsive: true,
          scales: { y: { beginAtZero: true } }
        }
      });
    }
    return () => { // Cleanup
      if (chartInstance) chartInstance.destroy();
    };
  }, [usersOverTimeData]); // Re-run if data changes

  // Effect for Promotions By Category Chart
  useEffect(() => {
    let chartInstance = null;
    if (promotionsByCategoryData && document.getElementById('promotionsByCategoryChart')) {
      const ctx = document.getElementById('promotionsByCategoryChart').getContext('2d');
      chartInstance = new Chart(ctx, {
        type: 'bar', // or 'pie'
        data: {
          labels: promotionsByCategoryData.map(d => d.category),
          datasets: [{
            label: 'Promotions',
            data: promotionsByCategoryData.map(d => d.count),
            backgroundColor: [ // Add more colors if more categories expected
              'rgba(255, 99, 132, 0.7)', 'rgba(54, 162, 235, 0.7)',
              'rgba(255, 206, 86, 0.7)', 'rgba(75, 192, 192, 0.7)',
              'rgba(153, 102, 255, 0.7)', 'rgba(255, 159, 64, 0.7)'
            ],
            borderColor: [
              'rgba(255, 99, 132, 1)', 'rgba(54, 162, 235, 1)',
              'rgba(255, 206, 86, 1)', 'rgba(75, 192, 192, 1)',
              'rgba(153, 102, 255, 1)', 'rgba(255, 159, 64, 1)'
            ],
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          indexAxis: 'y', // For horizontal bar chart, if preferred
          scales: { x: { beginAtZero: true } }
        }
      });
    }
    return () => { // Cleanup
      if (chartInstance) chartInstance.destroy();
    };
  }, [promotionsByCategoryData]); // Re-run if data changes

  // Combined loading state for initial dashboard view (summary is key)
  if (loading) {
    return <div className="container text-center py-10"><i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i> Loading Admin Dashboard Summary...</div>;
  }

  // Error for summary data - critical for dashboard
  if (error && !summary) {
    return <div className="container text-center py-10 text-red-500">Error loading summary: {error}</div>;
  }

  // If summary is loaded, but then chart data fails, chartsError will be shown within the dashboard view.
  // Ensure UserManagement, MerchantManagement, PromotionManagement are available
  // They are expected to be declared at the top of this function's scope from window object.

  const renderCurrentView = () => {
    switch (currentView) {
      case 'users':
        return UserManagement ? <UserManagement /> : <p>User Management component not loaded.</p>;
      case 'merchants':
        return MerchantManagement ? <MerchantManagement /> : <p>Merchant Management component not loaded.</p>;
      case 'promotions':
        return PromotionManagement ? <PromotionManagement /> : <p>Promotion Management component not loaded.</p>;
      case 'dashboard':
      default:
        return (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-xl transition-shadow">
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Total Users</h3>
              <p className="text-3xl font-bold text-primary-color">{summary.totalUsers}</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-xl transition-shadow">
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Total Merchants</h3>
              <p className="text-3xl font-bold text-primary-color">{summary.totalMerchants}</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-xl transition-shadow">
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Total Promotions</h3>
              <p className="text-3xl font-bold text-primary-color">{summary.totalPromotions}</p>
            </div>
            <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-xl transition-shadow">
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Promotion Clicks</h3>
              <p className="text-3xl font-bold text-primary-color">{summary.totalPromotionClicks}</p>
            </div>
          </div>

          {/* Charts Section */}
          <div className="mt-8">
            <h2 className="text-2xl font-semibold text-gray-700 mb-4">Analytics Visualizations</h2>
            {chartsError && <p className="text-red-500 bg-red-100 p-3 rounded-md mb-4">Error loading chart data: {chartsError}</p>}

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Users Over Time Chart */}
              <div className="bg-white p-6 rounded-lg shadow-md">
                <h3 className="text-xl font-semibold text-gray-700 mb-3">New Users (Last 30 Days)</h3>
                {chartsLoading && !usersOverTimeData && <p><i className="fas fa-spinner fa-spin"></i> Loading chart...</p>}
                <canvas id="usersOverTimeChart"></canvas>
              </div>

              {/* Promotions By Category Chart */}
              <div className="bg-white p-6 rounded-lg shadow-md">
                <h3 className="text-xl font-semibold text-gray-700 mb-3">Promotions by Category</h3>
                {chartsLoading && !promotionsByCategoryData && <p><i className="fas fa-spinner fa-spin"></i> Loading chart...</p>}
                <canvas id="promotionsByCategoryChart"></canvas>
              </div>
            </div>
          </div>
        );
    }
  };


  return (
    <div className="container mx-auto p-4 md:p-8 bg-gray-50 min-h-screen">
      <header className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-primary-color mb-2">Admin Panel</h1>
        <p className="text-gray-600">Manage users, merchants, promotions, and view site analytics.</p>
      </header>

      <nav className="mb-8 flex flex-wrap gap-4">
        <button
          onClick={() => setCurrentView('dashboard')}
          className={`px-4 py-2 rounded-md font-medium transition-colors ${currentView === 'dashboard' ? 'bg-primary-color text-white' : 'bg-white text-gray-700 hover:bg-gray-100'}`}>
          <i className="fas fa-tachometer-alt mr-2"></i>Dashboard
        </button>
        <button
          onClick={() => setCurrentView('users')}
          className={`px-4 py-2 rounded-md font-medium transition-colors ${currentView === 'users' ? 'bg-primary-color text-white' : 'bg-white text-gray-700 hover:bg-gray-100'}`}>
          <i className="fas fa-users mr-2"></i>User Management
        </button>
        <button
          onClick={() => setCurrentView('merchants')}
          className={`px-4 py-2 rounded-md font-medium transition-colors ${currentView === 'merchants' ? 'bg-primary-color text-white' : 'bg-white text-gray-700 hover:bg-gray-100'}`}>
          <i className="fas fa-store-alt mr-2"></i>Merchant Management
        </button>
        <button
          onClick={() => setCurrentView('promotions')}
          className={`px-4 py-2 rounded-md font-medium transition-colors ${currentView === 'promotions' ? 'bg-primary-color text-white' : 'bg-white text-gray-700 hover:bg-gray-100'}`}>
          <i className="fas fa-tags mr-2"></i>Promotion Management
        </button>
      </nav>

      <section id="admin-content">
        {renderCurrentView()}
      </section>

    </div>
  );
}

// Make it globally available if not using ES6 modules and a bundler
window.AdminDashboard = AdminDashboard;
