import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import Footer from './components/Footer';
import DealsGrid from './components/DealsGrid';
import { Deal } from './types';
import { getDeals } from './api/deals';

const App: React.FC = () => {
  const [deals, setDeals] = useState<Deal[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDeals = async () => {
      try {
        const fetchedDeals = await getDeals();
        setDeals(fetchedDeals);
      } catch (error) {
        setError('Failed to fetch deals');
        console.error(error);
      }
    };

    fetchDeals();
  }, []);

  return (
    <div className="bg-gray-50">
      <Header />
      <main className="container mx-auto px-4 py-12">
        {error && <p className="text-red-500">{error}</p>}
        <DealsGrid deals={deals} />
      </main>
      <Footer />
    </div>
  );
};

export default App;
