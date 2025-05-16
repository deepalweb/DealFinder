function LoginPage() {
  const { useState } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [resetEmail, setResetEmail] = useState('');
  const [resetStatus, setResetStatus] = useState('');
  const [resetLoading, setResetLoading] = useState(false);

  // Check if user is already logged in
  React.useEffect(() => {
    const userData = localStorage.getItem('dealFinderUser');
    if (userData) {
      const user = JSON.parse(userData);
      if (user.role === 'merchant') {
        navigate('/merchant/dashboard');
      } else {
        navigate('/');
      }
    }
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // For demo purposes, allow direct login with demo credentials
      if (formData.email === 'demo@merchant.com' && formData.password === 'demo123') {
        // Create a demo merchant user object
        const demoUser = {
          _id: 'demo123',
          name: 'Demo User',
          email: 'demo@merchant.com',
          role: 'merchant',
          merchantId: 'demo456',
          businessName: 'Demo Merchant Shop'
        };
        
        // Store in localStorage
        localStorage.setItem('dealFinderUser', JSON.stringify(demoUser));
        
        // Navigate to merchant dashboard
        navigate('/merchant/dashboard');
        return;
      }

      // For real authentication, use the API
      const response = await window.API.Users.login(formData);
      
      // Store user data in localStorage (including token)
      localStorage.setItem('dealFinderUser', JSON.stringify(response));
      
      // Navigate based on user role
      if (response.role === 'merchant') {
        navigate('/merchant/dashboard');
      } else {
        navigate('/');
      }
    } catch (err) {
      console.error('Login error:', err);
      setError('Invalid email or password. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = (e) => {
    e.preventDefault();
    setFormData({
      email: 'demo@merchant.com',
      password: 'demo123'
    });
    
    // Submit the form with demo credentials
    setTimeout(() => {
      document.getElementById('login-form').dispatchEvent(new Event('submit', { cancelable: true, bubbles: true }));
    }, 100);
  };

  return (
    <div className="page-container">
      <div className="container py-8">
        <div className="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
          <h1 className="text-2xl font-bold mb-6 text-center">Login to Your Account</h1>
          
          {error && (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}
          
          <form id="login-form" onSubmit={handleSubmit}>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Email Address</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                required
              />
            </div>
            
            <div className="mb-6">
              <label className="block text-sm font-medium mb-1">Password</label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                required
              />
            </div>
            
            <div className="flex flex-col space-y-3">
              <button
                type="submit"
                className="w-full px-4 py-2 bg-primary-color text-white rounded-md hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-color"
                disabled={loading}
              >
                {loading ? 'Logging in...' : 'Login'}
              </button>
              
              <button
                type="button"
                onClick={handleDemoLogin}
                className="w-full px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
              >
                Login as Demo Merchant
              </button>
            </div>
          </form>
          
          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              <a href="/reset-password" onClick={e => { e.preventDefault(); navigate('/reset-password'); }} className="text-primary-color hover:underline">
                Forgot your password?
              </a>
            </p>
            <p className="text-sm text-gray-600 mt-2">
              Don't have an account?{' '}
              <a href="/register" onClick={e => { e.preventDefault(); navigate('/register'); }} className="text-primary-color hover:underline">
                Register here
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}