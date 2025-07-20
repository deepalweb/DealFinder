import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-800 text-white py-8">
      <div className="container mx-auto px-4">
        <div className="flex justify-between">
          <div>
            <h3 className="font-bold text-lg">DealFinder</h3>
            <p className="text-sm">Find the best deals around you.</p>
          </div>
          <div>
            <h3 className="font-bold text-lg">Links</h3>
            <ul>
              <li><a href="/about" className="text-sm hover:underline">About Us</a></li>
              <li><a href="/contact" className="text-sm hover:underline">Contact</a></li>
              <li><a href="/privacy" className="text-sm hover:underline">Privacy Policy</a></li>
            </ul>
          </div>
        </div>
        <div className="text-center text-sm mt-8">
          © {new Date().getFullYear()} DealFinder. All rights reserved.
        </div>
      </div>
    </footer>
  );
};

export default Footer;
