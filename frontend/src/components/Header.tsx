import React from 'react';

const Header: React.FC = () => {
  return (
    <header className="bg-white shadow-md">
      <div className="container mx-auto px-4 py-6 flex justify-between items-center">
        <h1 className="text-2xl font-bold text-primary-color">DealFinder</h1>
        <nav>
          <a href="/" className="text-gray-600 hover:text-primary-color px-3">Home</a>
          <a href="/deals" className="text-gray-600 hover:text-primary-color px-3">Deals</a>
          <a href="/login" className="text-gray-600 hover:text-primary-color px-3">Login</a>
        </nav>
      </div>
    </header>
  );
};

export default Header;
