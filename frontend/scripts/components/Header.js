function Header() {
  const { useState } = React;
  const { Link, useLocation } = ReactRouterDOM;
  const location = useLocation();

  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  const isActive = (path) => {
    return location.pathname === path ? 'active' : '';
  };

  return (
    <header className="header py-4" data-id="cn9iaj0zb" data-path="scripts/components/Header.js">
      <div className="container" data-id="br3iir1rf" data-path="scripts/components/Header.js">
        <div className="flex items-center justify-between" data-id="73oarsdto" data-path="scripts/components/Header.js">
          <Link to="/" className="logo flex items-center">
            <i className="fas fa-percent mr-2" data-id="edew4gie3" data-path="scripts/components/Header.js"></i>
            <span data-id="dq1j7431j" data-path="scripts/components/Header.js">DealFinder</span>
          </Link>
          
          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center space-x-4" data-id="cqq4el10w" data-path="scripts/components/Header.js">
            <Link to="/" className={`nav-link ${isActive('/')}`}>
              <i className="fas fa-home mr-1" data-id="w48099ykw" data-path="scripts/components/Header.js"></i> Home
            </Link>
            <Link to="/categories/all" className={`nav-link ${isActive('/categories/all')}`}>
              <i className="fas fa-tags mr-1" data-id="yidrhg00s" data-path="scripts/components/Header.js"></i> All Deals
            </Link>
            <Link to="/merchants" className={`nav-link ${isActive('/merchants')}`}>
              <i className="fas fa-store mr-1" data-id="9a3ef2ihd" data-path="scripts/components/Header.js"></i> Stores
            </Link>
            <Link to="/favorites" className={`nav-link ${isActive('/favorites')}`}>
              <i className="fas fa-heart mr-1" data-id="isegr597p" data-path="scripts/components/Header.js"></i> My Favorites
            </Link>
          </nav>
          
          {/* User Menu */}
          <div className="hidden md:block ml-4" data-id="rtyedyxvg" data-path="scripts/components/Header.js">
            <UserMenu />
          </div>
          
          {/* Mobile Menu Button */}
          <button
            className="md:hidden text-dark-gray focus:outline-none"
            onClick={toggleMenu} data-id="ugeodb546" data-path="scripts/components/Header.js">

            <i className={`fas ${isMenuOpen ? 'fa-times' : 'fa-bars'} text-xl`} data-id="kulkvo57h" data-path="scripts/components/Header.js"></i>
          </button>
        </div>
        
        {/* Mobile Menu */}
        {isMenuOpen &&
        <div className="mt-4 md:hidden" data-id="ymgkxkz08" data-path="scripts/components/Header.js">
            <nav className="flex flex-col space-y-2" data-id="7kyb92ait" data-path="scripts/components/Header.js">
              <Link to="/" className={`nav-link ${isActive('/')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-home mr-1" data-id="693d7nucb" data-path="scripts/components/Header.js"></i> Home
              </Link>
              <Link to="/categories/all" className={`nav-link ${isActive('/categories/all')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-tags mr-1" data-id="eh8lt52a1" data-path="scripts/components/Header.js"></i> All Deals
              </Link>
              <Link to="/merchants" className={`nav-link ${isActive('/merchants')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-store mr-1" data-id="hm9fk8u1y" data-path="scripts/components/Header.js"></i> Stores
              </Link>
              <Link to="/favorites" className={`nav-link ${isActive('/favorites')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-heart mr-1" data-id="tlcymhlrl" data-path="scripts/components/Header.js"></i> My Favorites
              </Link>
              <Link to="/categories/fashion" className={`nav-link ${isActive('/categories/fashion')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-shirt mr-1" data-id="57y1u0gf9" data-path="scripts/components/Header.js"></i> Fashion
              </Link>
              <Link to="/categories/electronics" className={`nav-link ${isActive('/categories/electronics')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-laptop mr-1" data-id="4fcbp2tq2" data-path="scripts/components/Header.js"></i> Electronics
              </Link>
              <Link to="/categories/food" className={`nav-link ${isActive('/categories/food')}`} onClick={() => setIsMenuOpen(false)}>
                <i className="fas fa-utensils mr-1" data-id="9m4lfy8jk" data-path="scripts/components/Header.js"></i> Food
              </Link>
              <div className="pt-2 mt-2 border-t border-gray-200" data-id="1r1o83nec" data-path="scripts/components/Header.js">
                <UserMenu />
              </div>
            </nav>
          </div>
        }
      </div>
    </header>);

}