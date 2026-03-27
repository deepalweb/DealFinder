function Header() {
  const { useState, useEffect } = React;
  const { Link, useLocation } = ReactRouterDOM;
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isDark, setIsDark] = useState(() => document.documentElement.getAttribute('data-theme') === 'dark');

  useEffect(() => {
    const saved = localStorage.getItem('df-theme');
    if (saved === 'dark') {
      document.documentElement.setAttribute('data-theme', 'dark');
      setIsDark(true);
    }
  }, []);

  const toggleDark = () => {
    const next = !isDark;
    setIsDark(next);
    document.documentElement.setAttribute('data-theme', next ? 'dark' : 'light');
    localStorage.setItem('df-theme', next ? 'dark' : 'light');
  };

  const isActive = (path) => location.pathname === path ? 'active' : '';

  return (
    <header className="header py-3">
      <div className="container">
        <div className="flex items-center justify-between">
          <Link to="/" className="logo flex items-center gap-2">
            <span style={{background:'linear-gradient(135deg,#6366f1,#f43f5e)',borderRadius:'0.5rem',padding:'0.25rem 0.5rem',color:'#fff',fontSize:'1rem'}}>%</span>
            DealFinder
          </Link>

          <nav className="hidden md:flex items-center space-x-1">
            <Link to="/" className={`nav-link ${isActive('/')}`}><i className="fas fa-home mr-1"></i>Home</Link>
            <Link to="/categories/all" className={`nav-link ${isActive('/categories/all')}`}><i className="fas fa-tags mr-1"></i>All Deals</Link>
            <Link to="/merchants" className={`nav-link ${isActive('/merchants')}`}><i className="fas fa-store mr-1"></i>Stores</Link>
            <Link to="/favorites" className={`nav-link ${isActive('/favorites')}`}><i className="fas fa-heart mr-1"></i>Favorites</Link>
            <Link to="/nearby" className={`nav-link ${isActive('/nearby')}`}><i className="fas fa-map-marker-alt mr-1"></i>Nearby</Link>
          </nav>

          <div className="hidden md:flex items-center gap-3">
            <button className="dark-toggle" onClick={toggleDark} title={isDark ? 'Light mode' : 'Dark mode'}>
              <i className={`fas ${isDark ? 'fa-sun' : 'fa-moon'}`}></i>
            </button>
            <UserMenu />
          </div>

          <div className="flex items-center gap-2 md:hidden">
            <button className="dark-toggle" onClick={toggleDark}>
              <i className={`fas ${isDark ? 'fa-sun' : 'fa-moon'}`}></i>
            </button>
            <button className="dark-toggle" onClick={() => setIsMenuOpen(!isMenuOpen)}>
              <i className={`fas ${isMenuOpen ? 'fa-times' : 'fa-bars'}`}></i>
            </button>
          </div>
        </div>

        {isMenuOpen && (
          <div className="mt-3 md:hidden pb-3 border-t" style={{borderColor:'var(--border-color)'}}>
            <nav className="flex flex-col space-y-1 pt-3">
              {[['/',  'fa-home', 'Home'], ['/categories/all', 'fa-tags', 'All Deals'], ['/merchants', 'fa-store', 'Stores'], ['/favorites', 'fa-heart', 'Favorites'], ['/nearby', 'fa-map-marker-alt', 'Nearby']].map(([path, icon, label]) => (
                <Link key={path} to={path} className={`nav-link ${isActive(path)}`} onClick={() => setIsMenuOpen(false)}>
                  <i className={`fas ${icon} mr-2`}></i>{label}
                </Link>
              ))}
              <div className="pt-2 mt-2 border-t" style={{borderColor:'var(--border-color)'}}>
                <UserMenu />
              </div>
            </nav>
          </div>
        )}
      </div>
    </header>
  );
}