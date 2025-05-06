function App() {
  const { Routes, Route, BrowserRouter, Navigate } = ReactRouterDOM;

  return (
    <BrowserRouter>
      <div className="app" data-id="r0xonczkt" data-path="scripts/App.js">
        <Header />
        <main data-id="mbwshduxb" data-path="scripts/App.js">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/categories/:categoryId" element={<CategoryPage />} />
            <Route path="/favorites" element={<FavoritesPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/profile" element={<UserProfile />} />
            <Route path="/merchants" element={<MerchantListPage />} />
            <Route path="/merchants/:merchantId" element={<MerchantProfilePage />} />
            <Route path="/merchant/dashboard" element={<MerchantDashboard />} />
            <Route path="/notification-settings" element={<NotificationsPage />} />
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