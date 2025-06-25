// Import static pages so they are available in this scope
// prettier-ignore
const AboutPage = window.AboutPage;
const ContactPage = window.ContactPage;
const PrivacyPolicyPage = window.PrivacyPolicyPage;
const ResetPasswordPage = window.ResetPasswordPage;
const ResetPasswordConfirmPage = window.ResetPasswordConfirmPage;

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
            <Route path="/admin" element={<window.AdminDashboard />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
        <Footer />
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