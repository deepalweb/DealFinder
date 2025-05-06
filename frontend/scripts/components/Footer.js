function Footer() {
  const { Link } = ReactRouterDOM;

  return (
    <footer className="footer mt-12" data-id="b5ziqy7by" data-path="scripts/components/Footer.js">
      <div className="container" data-id="v5znx4u61" data-path="scripts/components/Footer.js">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8" data-id="0yj2semtq" data-path="scripts/components/Footer.js">
          <div data-id="8mza5c0dt" data-path="scripts/components/Footer.js">
            <h3 className="footer-title" data-id="ujou83o6d" data-path="scripts/components/Footer.js">DealFinder</h3>
            <p className="text-sm text-gray-300 mb-4" data-id="z8ejvx0du" data-path="scripts/components/Footer.js">
              Your destination for the best discounts and promotions from your favorite brands.
            </p>
            <div className="flex" data-id="gzg5udhij" data-path="scripts/components/Footer.js">
              <a href="#" className="social-icon" data-id="1k7qa07ax" data-path="scripts/components/Footer.js"><i className="fab fa-facebook-f" data-id="r4v7njvw0" data-path="scripts/components/Footer.js"></i></a>
              <a href="#" className="social-icon" data-id="c7n55t1ul" data-path="scripts/components/Footer.js"><i className="fab fa-twitter" data-id="tc6ux2pnl" data-path="scripts/components/Footer.js"></i></a>
              <a href="#" className="social-icon" data-id="3u85defd1" data-path="scripts/components/Footer.js"><i className="fab fa-instagram" data-id="5x14rqsgs" data-path="scripts/components/Footer.js"></i></a>
              <a href="#" className="social-icon" data-id="7k37bnxsv" data-path="scripts/components/Footer.js"><i className="fab fa-pinterest" data-id="73ta5xufr" data-path="scripts/components/Footer.js"></i></a>
            </div>
          </div>
          
          <div data-id="q710ed2o0" data-path="scripts/components/Footer.js">
            <h3 className="footer-title" data-id="mu4d5g3cg" data-path="scripts/components/Footer.js">Categories</h3>
            <Link to="/categories/fashion" className="footer-link">Fashion</Link>
            <Link to="/categories/electronics" className="footer-link">Electronics</Link>
            <Link to="/categories/travel" className="footer-link">Travel</Link>
            <Link to="/categories/food" className="footer-link">Food & Dining</Link>
            <Link to="/categories/health" className="footer-link">Health & Wellness</Link>
          </div>
          
          <div data-id="p2p68fmkc" data-path="scripts/components/Footer.js">
            <h3 className="footer-title" data-id="ks9knxcmi" data-path="scripts/components/Footer.js">Quick Links</h3>
            <Link to="/" className="footer-link">Home</Link>
            <Link to="/categories/all" className="footer-link">All Deals</Link>
            <a href="#" className="footer-link" data-id="g8zdcl60s" data-path="scripts/components/Footer.js">About Us</a>
            <a href="#" className="footer-link" data-id="ioape7k6p" data-path="scripts/components/Footer.js">Contact</a>
            <a href="#" className="footer-link" data-id="ket3rqfdo" data-path="scripts/components/Footer.js">Privacy Policy</a>
          </div>
          
          <div data-id="exal2stat" data-path="scripts/components/Footer.js">
            <h3 className="footer-title" data-id="mezkoc1ln" data-path="scripts/components/Footer.js">Newsletter</h3>
            <p className="text-sm text-gray-300 mb-4" data-id="bxv62n2mj" data-path="scripts/components/Footer.js">
              Subscribe to our newsletter for the latest deals and promotions.
            </p>
            <form data-id="0qjsrqcjk" data-path="scripts/components/Footer.js">
              <input
                type="email"
                placeholder="Your email address"
                className="newsletter-input"
                required data-id="zcuri1bsd" data-path="scripts/components/Footer.js" />

              <button type="submit" className="btn btn-primary w-full" data-id="yxojsldtw" data-path="scripts/components/Footer.js">
                Subscribe
              </button>
            </form>
          </div>
        </div>
        
        <div className="border-t border-gray-700 mt-8 pt-8 text-center text-sm text-gray-400" data-id="l9wogqm2y" data-path="scripts/components/Footer.js">
          <p data-id="vae0ew36t" data-path="scripts/components/Footer.js">© {new Date().getFullYear()} DealFinder. All rights reserved.</p>
        </div>
      </div>
    </footer>);

}