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
      <div className="flex items-center space-x-4" data-id="y0ckerqo0" data-path="scripts/components/UserMenu.js">
        <Link to="/login" className="text-dark-gray hover:text-primary-color">
          Login
        </Link>
        <Link to="/register" className="btn btn-primary py-1 px-3 text-sm">
          Sign Up
        </Link>
      </div>);

  }

  return (
    <div className="relative" ref={menuRef} data-id="ac1u48s87" data-path="scripts/components/UserMenu.js">
      <button
        onClick={toggleMenu}
        className="flex items-center focus:outline-none"
        aria-label="User menu"
        aria-expanded={isMenuOpen} data-id="x3q7nc5wq" data-path="scripts/components/UserMenu.js">

        <span className="hidden md:block mr-2" data-id="it6ihhi12" data-path="scripts/components/UserMenu.js">{user.name}</span>
        <div className="w-9 h-9 bg-primary-color rounded-full flex items-center justify-center text-white font-bold" data-id="0a78zvimu" data-path="scripts/components/UserMenu.js">
          {user.name.charAt(0)}
        </div>
      </button>
      
      {isMenuOpen &&
      <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-10" data-id="37owmfxpj" data-path="scripts/components/UserMenu.js">
          {user.role === 'merchant' ?
        <Link
          to="/merchant/dashboard"
          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          onClick={() => setIsMenuOpen(false)}>

              <i className="fas fa-store mr-2" data-id="n5u7l16lq" data-path="scripts/components/UserMenu.js"></i> Merchant Dashboard
            </Link> :

        <Link
          to="/profile"
          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          onClick={() => setIsMenuOpen(false)}>

              <i className="fas fa-user mr-2" data-id="7ubms8acy" data-path="scripts/components/UserMenu.js"></i> My Profile
            </Link>
        }
          
          <Link
          to="/favorites"
          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          onClick={() => setIsMenuOpen(false)}>

            <i className="fas fa-heart mr-2" data-id="58e1x1o8y" data-path="scripts/components/UserMenu.js"></i> My Favorites
          </Link>
          
          <Link
          to="/notification-settings"
          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          onClick={() => setIsMenuOpen(false)}>

            <i className="fas fa-bell mr-2" data-id="0399rxnme" data-path="scripts/components/UserMenu.js"></i> Notification Settings
          </Link>
          
          <hr className="my-1" data-id="n29940ida" data-path="scripts/components/UserMenu.js" />
          
          <button
          onClick={handleLogout}
          className="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-gray-100" data-id="yxx30ayn9" data-path="scripts/components/UserMenu.js">

            <i className="fas fa-sign-out-alt mr-2" data-id="5wvsvbu39" data-path="scripts/components/UserMenu.js"></i> Logout
          </button>
        </div>
      }
    </div>);

}