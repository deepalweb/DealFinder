function Footer() {
  const { Link } = ReactRouterDOM;

  return (
    <footer className="footer mt-12 bg-primary-dark text-white py-8">
      <div className="container">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div>
            <h3 className="footer-title flex items-center gap-2 text-xl font-bold mb-2">
              <i className="fas fa-percent"></i> DealFinder
            </h3>
            <p className="text-sm text-gray-200 mb-4 flex items-center gap-2">
              <i className="fas fa-bolt"></i> Your destination for the best discounts and promotions from your favorite brands.
            </p>
            <div className="flex gap-3 mt-2">
              <a href="#" className="social-icon hover:scale-110 transition-transform" title="Facebook"><i className="fab fa-facebook-f"></i></a>
              <a href="#" className="social-icon hover:scale-110 transition-transform" title="Twitter"><i className="fab fa-twitter"></i></a>
              <a href="#" className="social-icon hover:scale-110 transition-transform" title="Instagram"><i className="fab fa-instagram"></i></a>
              <a href="#" className="social-icon hover:scale-110 transition-transform" title="Pinterest"><i className="fab fa-pinterest"></i></a>
            </div>
          </div>
          
          <div>
            <h3 className="footer-title" data-id="mu4d5g3cg" data-path="scripts/components/Footer.js">Categories</h3>
            <Link to="/categories/fashion" className="footer-link">Fashion</Link>
            <Link to="/categories/electronics" className="footer-link">Electronics</Link>
            <Link to="/categories/travel" className="footer-link">Travel</Link>
            <Link to="/categories/food" className="footer-link">Food & Dining</Link>
            <Link to="/categories/health" className="footer-link">Health & Wellness</Link>
          </div>
          
          <div>
            <h3 className="footer-title" data-id="ks9knxcmi" data-path="scripts/components/Footer.js">Quick Links</h3>
            <Link to="/" className="footer-link">Home</Link>
            <Link to="/categories/all" className="footer-link">All Deals</Link>
            <Link to="/about" className="footer-link">About Us</Link>
            <Link to="/contact" className="footer-link">Contact</Link>
            <Link to="/privacy" className="footer-link">Privacy Policy</Link>
          </div>
          
          <div>
            <h3 className="footer-title flex items-center gap-2 text-lg font-semibold mb-2">
              <i className="fas fa-envelope"></i> Newsletter
            </h3>
            <p className="text-sm text-gray-200 mb-4 flex items-center gap-2">
              <i className="fas fa-paper-plane"></i> Subscribe to our newsletter for the latest deals and promotions.
            </p>
            <form className="flex flex-col sm:flex-row gap-2 items-stretch sm:items-center">
              <input
                type="email"
                placeholder="Your email address"
                className="newsletter-input flex-1 px-3 py-2 rounded-md border border-gray-300 text-gray-800"
                required
              />
              <button type="submit" className="btn btn-accent flex items-center gap-1 px-3 py-2 text-sm rounded h-full self-end sm:self-auto sm:h-auto hover:scale-105 transition-transform min-w-0">
                <i className="fas fa-paper-plane text-sm"></i> Subscribe
              </button>
            </form>
          </div>
        </div>
        <div className="text-center text-xs text-gray-300 mt-8 flex items-center justify-center gap-2">
          <i className="far fa-copyright"></i> {new Date().getFullYear()} DealFinder. All rights reserved.
        </div>
      </div>
    </footer>
  );

}