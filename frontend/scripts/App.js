// Import static pages so they are available in this scope
// prettier-ignore
const AboutPage = window.AboutPage;
const ContactPage = window.ContactPage;
const PrivacyPolicyPage = window.PrivacyPolicyPage;
const ResetPasswordPage = window.ResetPasswordPage;
const ResetPasswordConfirmPage = window.ResetPasswordConfirmPage;

// Admin Pages
const AdminLayout = window.AdminLayout;
const AdminDashboardPage = window.AdminDashboardPage;
const AdminUsersPage = window.AdminUsersPage;
const AdminMerchantsPage = window.AdminMerchantsPage;
const AdminPromotionsPage = window.AdminPromotionsPage;

// Helper for admin routes
const AdminRoute = ({ children }) => {
  const { isAdmin, loading } = useAuth(); // Assuming a useAuth hook that checks admin role

  if (loading) {
    return React.createElement('div', null, 'Loading...'); // Or some loading spinner
  }

  if (!isAdmin()) {
    // If not admin, redirect to home or login page
    // For now, let's assume Navigate is available in this scope
    // and redirecting to home.
    // You might want to redirect to a login page or show an unauthorized message.
    return React.createElement(ReactRouterDOM.Navigate, { to: "/", replace: true });
  }

  return React.createElement(AdminLayout, null, children);
};


function App() {
  const { Routes, Route, BrowserRouter, Navigate } = ReactRouterDOM;

  return (
    <BrowserRouter>
      <div className="app" data-id="r0xonczkt" data-path="scripts/App.js">
        <Header />
        <main data-id="mbwshduxb" data-path="scripts/App.js">
          <Routes>
            <Route path="/" element={<window.HomePage />} />
            <Route path="/categories/:categoryId" element={<window.CategoryPage />} />
            <Route path="/favorites" element={<window.FavoritesPage />} />
            <Route path="/login" element={<window.LoginPage />} />
            <Route path="/register" element={<window.RegisterPage />} />
            <Route path="/profile" element={<window.UserProfile />} />
            <Route path="/merchants" element={<window.MerchantListPage />} />
            <Route path="/merchants/:merchantId" element={<window.MerchantProfilePage />} />
            <Route path="/merchant/dashboard" element={<window.MerchantDashboard />} />
            <Route path="/notification-settings" element={<window.NotificationsPage />} />
            <Route path="/about" element={<AboutPage />} />
            <Route path="/contact" element={<ContactPage />} />
            <Route path="/privacy" element={<PrivacyPolicyPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />
            <Route path="/reset-password/confirm" element={<ResetPasswordConfirmPage />} />
            <Route path="/deal/:dealId" element={<window.DealPage />} />

            {/* Admin Routes */}
            <Route path="/admin/dashboard" element={React.createElement(AdminRoute, null, React.createElement(AdminDashboardPage))} />
            <Route path="/admin/users" element={React.createElement(AdminRoute, null, React.createElement(AdminUsersPage))} />
            <Route path="/admin/merchants" element={React.createElement(AdminRoute, null, React.createElement(AdminMerchantsPage))} />
            <Route path="/admin/promotions" element={React.createElement(AdminRoute, null, React.createElement(AdminPromotionsPage))} />
            {/* Catch-all for admin routes, redirect to admin dashboard */}
            <Route path="/admin/*" element={React.createElement(AdminRoute, null, React.createElement(ReactRouterDOM.Navigate, { to: "/admin/dashboard", replace: true }))} />


            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
        {/* Footer might be excluded from admin panel or styled differently via AdminLayout */}
        { window.location.pathname.startsWith('/admin') ? null : React.createElement(Footer) }
      </div>
    </BrowserRouter>);

}

// Configure tailwind with custom colors
tailwind.config = {
  theme: {
    extend: {
      colors: {
        'primary-color': '#6366f1',
        'primary-dark': '#4f46e5',
        'secondary-color': '#f43f5e',
        'accent-color': '#10b981',
        'discount-red': '#ef4444'
      }
    }
  }
};

// Render the React application
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);