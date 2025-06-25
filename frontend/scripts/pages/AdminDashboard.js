// AdminDashboard.js
function AdminDashboard() {
  const { useState, useEffect } = React;
  const { Link, useNavigate } = ReactRouterDOM;

  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
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

    const fetchSummary = async () => {
      try {
        setLoading(true);
        if (window.API && window.API.Admin && window.API.Admin.getSummary) {
          const data = await window.API.Admin.getSummary();
          setSummary(data);
        } else {
          throw new Error("Admin API not available.");
        }
      } catch (e) {
        console.error("Failed to fetch admin summary:", e);
        setError('Failed to load summary data. ' + e.message);
      } finally {
        setLoading(false);
      }
    };

    fetchSummary();
  }, [navigate]);

  if (loading) {
    return <div className="container text-center py-10"><i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i> Loading Admin Dashboard...</div>;
  }

  if (error) {
    return <div className="container text-center py-10 text-red-500">Error: {error}</div>;
  }

  if (!summary) {
    return <div className="container text-center py-10">No summary data available.</div>;
  }

  // Placeholder for navigation state
  const [currentView, setCurrentView] = useState('dashboard'); // 'dashboard', 'users', 'merchants', 'promotions'

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
