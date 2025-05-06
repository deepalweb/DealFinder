function RegisterPage() {
  const { useState } = React;
  const { useNavigate, Link } = ReactRouterDOM;
  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    role: 'user', // Default role is 'user'
    businessName: '', // Only required for merchants
    notifications: true
  });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === 'checkbox' ? checked : value
    });
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors({
        ...errors,
        [name]: ''
      });
    }
  };

  const validateForm = () => {
    const newErrors = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Name is required';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Password must be at least 6 characters';
    }

    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    // Validate business name for merchants
    if (formData.role === 'merchant' && !formData.businessName.trim()) {
      newErrors.businessName = 'Business name is required for merchant accounts';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validateForm()) return;

    setLoading(true);

    try {
      // Register user via API
      const userData = { 
        name: formData.name,
        email: formData.email,
        password: formData.password,
        role: formData.role,
        businessName: formData.role === 'merchant' ? formData.businessName : undefined
      };
      
      // Call the API to register the user
      const response = await window.API.Users.register(userData);
      
      // Save user to localStorage
      localStorage.setItem('dealFinderUser', JSON.stringify(response));

      // Redirect based on user role
      if (response.role === 'merchant') {
        navigate('/merchant/dashboard');
      } else {
        navigate('/');
      }

    } catch (error) {
      console.error('Registration error:', error);
      setErrors({
        form: 'Registration failed. This email may already be in use.'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="page-container">
      <div className="container py-8">
        <div className="max-w-md mx-auto bg-white rounded-lg shadow-md p-6">
          <h1 className="text-2xl font-bold mb-6 text-center">Create an Account</h1>
          
          {errors.form &&
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
              {errors.form}
            </div>
          }
          
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label htmlFor="name" className="block text-sm font-medium mb-1">Full Name</label>
              <input
                type="text"
                id="name"
                name="name"
                className={`w-full px-3 py-2 border ${errors.name ? 'border-red-500' : 'border-gray-300'} rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color`}
                value={formData.name}
                onChange={handleChange} />
              {errors.name && <p className="text-red-500 text-xs mt-1">{errors.name}</p>}
            </div>
            
            <div className="mb-4">
              <label htmlFor="email" className="block text-sm font-medium mb-1">Email</label>
              <input
                type="email"
                id="email"
                name="email"
                className={`w-full px-3 py-2 border ${errors.email ? 'border-red-500' : 'border-gray-300'} rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color`}
                value={formData.email}
                onChange={handleChange} />
              {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email}</p>}
            </div>
            
            <div className="mb-4">
              <label htmlFor="password" className="block text-sm font-medium mb-1">Password</label>
              <input
                type="password"
                id="password"
                name="password"
                className={`w-full px-3 py-2 border ${errors.password ? 'border-red-500' : 'border-gray-300'} rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color`}
                value={formData.password}
                onChange={handleChange} />
              {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password}</p>}
            </div>
            
            <div className="mb-4">
              <label htmlFor="confirmPassword" className="block text-sm font-medium mb-1">Confirm Password</label>
              <input
                type="password"
                id="confirmPassword"
                name="confirmPassword"
                className={`w-full px-3 py-2 border ${errors.confirmPassword ? 'border-red-500' : 'border-gray-300'} rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color`}
                value={formData.confirmPassword}
                onChange={handleChange} />
              {errors.confirmPassword && <p className="text-red-500 text-xs mt-1">{errors.confirmPassword}</p>}
            </div>
            
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Account Type</label>
              <div className="flex space-x-4 mt-1">
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="role"
                    value="user"
                    checked={formData.role === 'user'}
                    onChange={handleChange}
                    className="mr-2"
                  />
                  Regular User
                </label>
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="role"
                    value="merchant"
                    checked={formData.role === 'merchant'}
                    onChange={handleChange}
                    className="mr-2"
                  />
                  Merchant
                </label>
              </div>
            </div>
            
            {formData.role === 'merchant' && (
              <div className="mb-4">
                <label htmlFor="businessName" className="block text-sm font-medium mb-1">Business Name</label>
                <input
                  type="text"
                  id="businessName"
                  name="businessName"
                  className={`w-full px-3 py-2 border ${errors.businessName ? 'border-red-500' : 'border-gray-300'} rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color`}
                  value={formData.businessName}
                  onChange={handleChange}
                />
                {errors.businessName && <p className="text-red-500 text-xs mt-1">{errors.businessName}</p>}
              </div>
            )}
            
            <div className="mb-6">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="notifications"
                  name="notifications"
                  className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded"
                  checked={formData.notifications}
                  onChange={handleChange} />
                <label htmlFor="notifications" className="ml-2 block text-sm text-gray-700">
                  I want to receive notifications about deals and promotions
                </label>
              </div>
            </div>
            
            <button
              type="submit"
              className="w-full btn btn-primary py-2"
              disabled={loading}>
              {loading ?
              <span className="flex items-center justify-center">
                  <i className="fas fa-spinner fa-spin mr-2"></i> Creating Account...
                </span> :
              'Sign Up'}
            </button>
          </form>
          
          <div className="mt-4 text-center">
            <p className="text-sm text-gray-600">
              Already have an account? <Link to="/login" className="text-primary-color hover:underline">Log in</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}