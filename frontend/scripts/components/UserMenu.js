function UserMenu() {
  const { useState, useEffect, useRef } = React;
  const { Link, useNavigate } = ReactRouterDOM;

  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [user, setUser] = useState(null);
  const menuRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    // Check if user is logged in
    const userData = localStorage.getItem('dealFinderUser');
    if (userData) {
      setUser(JSON.parse(userData));
    }

    // Close menu when clicking outside
    const handleClickOutside = (event) => {
      if (menuRef.current && !menuRef.current.contains(event.target)) {
        setIsMenuOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  const handleLogout = () => {
    localStorage.removeItem('dealFinderUser');
    setUser(null);
    setIsMenuOpen(false);
    navigate('/');
  };

  if (!user) {
    return (
      <div className="flex items-center space-x-4">
        <Link to="/login" className="text-dark-gray hover:text-primary-color">
          Login
        </Link>
        <Link to="/register" className="btn btn-primary py-1 px-3 text-sm">
          Sign Up
        </Link>
      </div>);
  }

  return (
    <div className="relative" ref={menuRef}>
      <button
        onClick={toggleMenu}
        className="flex items-center focus:outline-none"
        aria-label="User menu"
        aria-expanded={isMenuOpen}>
        <span className="hidden md:block mr-2">{user.name}</span>
        <div className="w-9 h-9 bg-primary-color rounded-full flex items-center justify-center text-white font-bold">
          {user.name.charAt(0)}
        </div>
      </button>
      
      {isMenuOpen &&
      <div className="absolute right-0 mt-2 w-64 bg-white rounded-md shadow-lg py-1 z-10">
          <div className="px-4 py-3 border-b border-gray-200">
            <p className="font-semibold">{user.name}</p>
            <p className="text-sm text-gray-500">{user.email}</p>
            {user.role === 'merchant' && (
              <span className="inline-block mt-1 px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                Merchant Account
              </span>
            )}
          </div>
          
          <Link
            to="/profile"
            className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
            onClick={() => setIsMenuOpen(false)}>
            <i className="fas fa-user mr-2"></i> My Profile
          </Link>
          
          {user.role === 'merchant' &&
            <Link
              to="/merchant/dashboard"
              className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
              onClick={() => setIsMenuOpen(false)}>
              <i className="fas fa-store mr-2"></i> Merchant Dashboard
            </Link>
          }
          
          <Link
            to="/favorites"
            className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
            onClick={() => setIsMenuOpen(false)}>
            <i className="fas fa-heart mr-2"></i> My Favorites
          </Link>
          
          <Link
            to="/notification-settings"
            className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
            onClick={() => setIsMenuOpen(false)}>
            <i className="fas fa-bell mr-2"></i> Notification Settings
          </Link>
          
          <hr className="my-1" />
          
          <button
            onClick={handleLogout}
            className="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-100">
            <i className="fas fa-sign-out-alt mr-2"></i> Logout
          </button>
        </div>
      }
    </div>);
}