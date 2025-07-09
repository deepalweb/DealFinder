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
  // Directly use window.Auth.isAdmin()
  // For a more reactive UI, a proper context/hook for auth state would be better,
  // but this will work for basic role checking on route load.
  // The concept of 'loading' for auth state is simplified here.
  // If Auth.isLoggedIn() is false, and we are trying to access admin, it should redirect.
  // If Auth.isLoggedIn() is true, then Auth.isAdmin() is the deciding factor.

  const { useState, useEffect } = React;
  const [isAdminUser, setIsAdminUser] = useState(false);
  const [authChecked, setAuthChecked] = useState(false);

  useEffect(() => {
    // Check admin status once when component mounts or auth state might change
    // This simple effect doesn't react to login/logout events automatically
    // A full solution would involve an event system or context.
    setIsAdminUser(window.Auth.isAdmin());
    setAuthChecked(true);
  }, []); // Re-check if location changes, implying potential state change (though not ideal)

  if (!authChecked) {
    // Haven't checked auth status yet, can show loading or null
    return React.createElement('div', null, 'Checking authentication...');
  }

  if (!isAdminUser) {
    // Not an admin, or not logged in as one
    console.warn("AdminRoute: Access denied. User is not an admin or not logged in appropriately.");
    return React.createElement(ReactRouterDOM.Navigate, { to: "/login?message=admin_required", replace: true });
  }

  // If admin, render the layout and children
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