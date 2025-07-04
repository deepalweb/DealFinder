function MerchantDashboard() {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState('active');
  const [analyticsData, setAnalyticsData] = useState([]);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingPromotion, setEditingPromotion] = useState(null);

  // Form state for new/edit promotion
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    discount: '',
    code: '',
    category: 'electronics',
    startDate: '',
    endDate: '',
    image: '',
    url: '',
    featured: false // Add featured field to form state
  });

  // For image upload preview
  const [imagePreview, setImagePreview] = useState(null);

  // --- Analytics by Promotion ---
  const [selectedPromotionId, setSelectedPromotionId] = useState(null);
  const [promotionClicks, setPromotionClicks] = useState([]);

  useEffect(() => {
    // Load analytics data from localStorage
    const storedAnalytics = localStorage.getItem('dealFinderAnalytics');
    if (storedAnalytics) {
      try {
        setAnalyticsData(JSON.parse(storedAnalytics));
      } catch (error) {
        console.error('Error parsing analytics data:', error);
        setAnalyticsData([]);
      }
    }

    // Check if user is logged in and is a merchant
    const userData = localStorage.getItem('dealFinderUser');
    if (!userData) {
      navigate('/login');
      return;
    }
    const parsedUser = JSON.parse(userData);
    if (parsedUser.role !== 'merchant') {
      navigate('/');
      return;
    }
    setUser(parsedUser);

    // Only load merchant's promotions from API
    const fetchPromotions = async () => {
      try {
        setLoading(true);
        if (parsedUser.merchantId) {
          let data = await window.API.Promotions.getByMerchant(parsedUser.merchantId);
          if (!Array.isArray(data)) {
            console.warn('Expected array of promotions, got:', data);
            data = [];
          }
          data = data.map(p => ({ ...p, id: p._id }));
          setPromotions(data);
        } else {
          setPromotions([]);
        }
        setLoading(false);
      } catch (err) {
        console.error('Error fetching promotions:', err);
        setError('Failed to load promotions. Please try again later.');
        setLoading(false);
      }
    };

    fetchPromotions();
  }, []);

  // Reset form when opening modal
  useEffect(() => {
    if (isAddModalOpen && !editingPromotion) {
      // Set default dates for new promotion
      const today = new Date().toISOString().split('T')[0];
      const nextMonth = new Date();
      nextMonth.setMonth(nextMonth.getMonth() + 1);

      setFormData({
        title: '',
        description: '',
        discount: '',
        code: '',
        category: 'electronics',
        startDate: today,
        endDate: nextMonth.toISOString().split('T')[0],
        image: '',
        url: '',
        featured: false // Reset featured
      });
      setImagePreview(null);
    }
  }, [isAddModalOpen]);

  // Set form data when editing
  useEffect(() => {
    if (editingPromotion) {
      // Format dates for input fields (YYYY-MM-DD)
      const formatDateForInput = (dateString) => {
        const date = new Date(dateString);
        return date.toISOString().split('T')[0];
      };

      setFormData({
        title: editingPromotion.title,
        description: editingPromotion.description,
        discount: editingPromotion.discount,
        code: editingPromotion.code,
        category: editingPromotion.category,
        startDate: formatDateForInput(editingPromotion.startDate),
        endDate: formatDateForInput(editingPromotion.endDate),
        image: editingPromotion.image || '',
        url: editingPromotion.url || '',
        featured: !!editingPromotion.featured // Set featured from editing promotion
      });
      setImagePreview(editingPromotion.image || null);
      setIsAddModalOpen(true);
    }
  }, [editingPromotion]);

  // Fetch clicks for a selected promotion
  useEffect(() => {
    if (selectedPromotionId) {
      window.API.Promotions.getAnalyticsByPromotion(selectedPromotionId)
        .then(setPromotionClicks)
        .catch(() => setPromotionClicks([]));
    }
  }, [selectedPromotionId]);

  // Fetch analytics from backend for this merchant
  useEffect(() => {
    if (!user || !user.merchantId || activeTab !== 'analytics') return;
    window.API.Promotions.getAnalyticsByMerchant(user.merchantId)
      .then(setAnalyticsData)
      .catch((err) => {
        console.error('Error fetching analytics:', err);
        setAnalyticsData([]);
      });
  }, [user, user?.merchantId, activeTab, promotions.length]);

  const handleChange = (e) => {
    const { name, value, type, files, checked } = e.target;
    if (type === 'checkbox') {
      setFormData({
        ...formData,
        [name]: checked
      });
    } else if (type === 'file' && files && files[0]) {
      // Handle image file upload
      const file = files[0];
      const imageUrl = URL.createObjectURL(file);
      setImagePreview(imageUrl);

      // Create a FileReader to read the file and convert to data URL
      const reader = new FileReader();
      reader.onloadend = async () => {
        try {
          // Optimize the image before saving
          const optimizedImage = await window.optimizeImage(reader.result, 800, 0.8);

          setFormData({
            ...formData,
            image: optimizedImage
          });
        } catch (error) {
          console.error('Error optimizing image:', error);
          // Fall back to unoptimized image if optimization fails
          setFormData({
            ...formData,
            image: reader.result
          });
        }
      };
      reader.readAsDataURL(file);
    } else if (name === 'url' && value) {
      // Validate URL format
      const isValid = window.validateURL(value);

      if (!isValid && value) {
        alert('Please enter a valid URL starting with http:// or https://');
      }

      // Update form data regardless, to allow for correction
      setFormData({
        ...formData,
        [name]: value
      });
    } else {
      // Handle regular input changes
      setFormData({
        ...formData,
        [name]: value
      });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validate URL if provided
    if (formData.url && !window.validateURL(formData.url)) {
      alert('Please enter a valid URL starting with http:// or https://');
      return;
    }

    // Ensure merchantId is present before attempting to save
    if (!user || !user.merchantId) {
      console.error('Error saving promotion: merchantId is missing from user object.', user);
      alert('Cannot save promotion: Your merchant account is not properly configured. Please re-login or contact support.');
      return;
    }

    try {
      // Ensure featured is a boolean
      const promotionData = {
        ...formData,
        featured: Boolean(formData.featured), // Force boolean
        merchantId: user.merchantId // Now we know user.merchantId exists
      };

      let savedPromotion;

      if (editingPromotion) {
        // Update existing promotion
        savedPromotion = await window.API.Promotions.update(editingPromotion._id, promotionData);
        
        // Update local state
        setPromotions(prevPromotions => 
          prevPromotions.map(promo => 
            promo.id === editingPromotion.id ? savedPromotion : promo
          )
        );
      } else {
        // Create new promotion
        savedPromotion = await window.API.Promotions.create(promotionData);
        
        // Add to local state
        setPromotions(prevPromotions => [...prevPromotions, savedPromotion]);
      }

      // Close modal and reset
      setIsAddModalOpen(false);
      setEditingPromotion(null);
      
      // Show success message
      alert(editingPromotion ? 'Promotion updated successfully!' : 'Promotion created successfully!');
    } catch (err) {
      console.error('Error saving promotion:', err);
      alert(`Failed to ${editingPromotion ? 'update' : 'create'} promotion. Please try again.`);
    }
  };

  const handleEdit = (promotion) => {
    setEditingPromotion(promotion);
  };

  const handleDelete = async (id) => {
    if (confirm('Are you sure you want to delete this promotion?')) {
      try {
        // For real merchants, use the API
        await window.API.Promotions.delete(id);
        
        // Update local state
        setPromotions(prevPromotions => prevPromotions.filter(promo => promo.id !== id));
        
        alert('Promotion deleted successfully!');
      } catch (err) {
        console.error('Error deleting promotion:', err);
        alert('Failed to delete promotion. Please try again.');
      }
    }
  };

  const filteredPromotions = promotions.filter((promo) => {
    if (activeTab === 'active') {
      return promo.status === 'active';
    } else if (activeTab === 'expired') {
      return promo.status === 'expired';
    }
    return true;
  });

  // Filter analyticsData to only include clicks for this merchant's promotions
  const merchantPromotionIds = promotions.map(p => p.id);
  const filteredAnalyticsData = analyticsData.filter(item => {
    if (!item.promotion) return false;
    const promoId = item.promotion._id || item.promotion.id || item.promotion;
    return merchantPromotionIds.includes(promoId?.toString());
  });

  // Compute click counts per promotion using backend analyticsData
  const clickCounts = promotions.reduce((acc, promo) => {
    acc[promo.id] = analyticsData.filter(a => {
      if (!a.promotion) return false;
      const promoId = a.promotion._id || a.promotion.id || a.promotion;
      return promoId?.toString() === promo.id?.toString();
    }).length;
    return acc;
  }, {});

  const formatDate = (dateString) => {
    const options = { year: 'numeric', month: 'short', day: 'numeric' };
    return new Date(dateString).toLocaleDateString('en-US', options);
  };

  if (!user) {
    return (
      <div className="page-container">
        <div className="container py-8 text-center">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
        </div>
      </div>);
  }

  if (loading) {
    return (
      <div className="page-container">
        <div className="container py-8 text-center">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
          <p className="mt-4 text-gray-600">Loading promotions...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="page-container">
        <div className="container py-8 text-center">
          <i className="fas fa-exclamation-circle text-3xl text-red-500"></i>
          <p className="mt-4 text-gray-600">{error}</p>
          <button 
            className="mt-4 px-4 py-2 bg-primary-color text-white rounded-md"
            onClick={() => window.location.reload()}>
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      <div className="container py-8">
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex justify-between items-center mb-6">
            <h1 className="text-2xl font-bold flex items-center">
              <i className="fas fa-store text-primary-color mr-2"></i>
              {user.businessName || 'Merchant Dashboard'}
            </h1>
            <button
              className="btn btn-primary"
              onClick={() => {
                setEditingPromotion(null);
                setIsAddModalOpen(true);
              }}>
              <i className="fas fa-plus mr-2"></i> Add New Promotion
            </button>
          </div>
          
          <div className="mb-6">
            <div className="flex border-b">
              <button
                className={`py-2 px-4 font-medium ${activeTab === 'active' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                onClick={() => setActiveTab('active')}>
                Active Promotions
              </button>
              <button
                className={`py-2 px-4 font-medium ${activeTab === 'expired' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                onClick={() => setActiveTab('expired')}>
                Expired Promotions
              </button>
              <button
                className={`py-2 px-4 font-medium ${activeTab === 'all' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                onClick={() => setActiveTab('all')}>
                All Promotions
              </button>
              <button
                className={`py-2 px-4 font-medium ${activeTab === 'analytics' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                onClick={() => setActiveTab('analytics')}>
                Click Analytics
              </button>
            </div>
          </div>
          
          {activeTab === 'analytics' ?
            <div>
              <div className="mb-6">
                <h2 className="text-xl font-semibold mb-2">Promotion Click Analytics</h2>
                <p className="text-gray-600">Track how users interact with your promotions</p>
              </div>
              {/* Summary Table: Clicks per Promotion */}
              <div className="mb-8">
                <h3 className="text-md font-semibold mb-2">Clicks by Promotion</h3>
                <table className="w-full table-auto mb-2">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Promotion</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Clicks</th>
                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Details</th>
                    </tr>
                  </thead>
                  <tbody>
                    {promotions.map((promo) => (
                      <tr key={promo.id} className="border-b">
                        <td className="px-4 py-2">{promo.title}</td>
                        <td className="px-4 py-2">{clickCounts[promo.id] || 0}</td>
                        <td className="px-4 py-2">
                          <button
                            className={`text-sm ${selectedPromotionId === promo.id ? 'text-primary-color font-bold' : 'text-blue-600 underline'}`}
                            onClick={() => setSelectedPromotionId(promo.id)}>
                            {selectedPromotionId === promo.id ? 'Viewing' : 'View'}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {/* Detailed Clicks for Selected Promotion */}
              {selectedPromotionId && (
                <div className="mb-8">
                  <h3 className="text-md font-semibold mb-2">Click Details for: {promotions.find(p => p.id === selectedPromotionId)?.title || ''}</h3>
                  {promotionClicks.length === 0 ? (
                    <div className="text-gray-500">No clicks yet for this promotion.</div>
                  ) : (
                    <table className="w-full table-auto">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Date & Time</th>
                          <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                        </tr>
                      </thead>
                      <tbody>
                        {promotionClicks.map((click, idx) => (
                          <tr key={click._id || idx} className="border-b">
                            <td className="px-4 py-2">{click.user ? (click.user.name || click.user.email) : 'Guest'}</td>
                            <td className="px-4 py-2">{new Date(click.timestamp).toLocaleString()}</td>
                            <td className="px-4 py-2">{click.type}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              )}
              
              <div className="mt-8 p-4 bg-gray-50 rounded-lg">
                <h3 className="text-md font-semibold mb-2">Analytics Insights</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="bg-white p-4 rounded-md shadow-sm">
                    <div className="text-2xl font-bold text-primary-color">{filteredAnalyticsData.length}</div>
                    <div className="text-sm text-gray-500">Total Clicks</div>
                  </div>
                  <div className="bg-white p-4 rounded-md shadow-sm">
                    <div className="text-2xl font-bold text-primary-color">
                      {filteredAnalyticsData.filter((item) => {
                      const clickDate = new Date(item.timestamp);
                      const today = new Date();
                      return clickDate.toDateString() === today.toDateString();
                    }).length}
                    </div>
                    <div className="text-sm text-gray-500">Today's Clicks</div>
                  </div>
                  <div className="bg-white p-4 rounded-md shadow-sm">
                    <div className="text-2xl font-bold text-primary-color">
                      {Array.from(new Set(filteredAnalyticsData.map((item) => item.promotionId))).length}
                    </div>
                    <div className="text-sm text-gray-500">Unique Promotions Clicked</div>
                  </div>
                </div>
              </div>
            </div> :
          filteredPromotions.length === 0 ?
          <div className="text-center py-10">
              <i className="fas fa-tag text-gray-300 text-5xl mb-4"></i>
              <p className="text-gray-500 mb-4">No {activeTab !== 'all' ? activeTab : ''} promotions found</p>
              <button
              className="btn btn-primary"
              onClick={() => {
                setEditingPromotion(null);
                setIsAddModalOpen(true);
              }}>
                Create Your First Promotion
              </button>
            </div> :

          <div className="overflow-x-auto">
              <table className="w-full table-auto">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Promotion</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Discount</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Code</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dates</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredPromotions.map((promotion) =>
    <tr key={promotion.id}>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          {promotion.image &&
                      <div className="flex-shrink-0 h-10 w-10 mr-4">
                              <img className="h-10 w-10 rounded-md object-cover" src={promotion.image} alt={promotion.title} />
                            </div>
                      }
                          <div>
                            <div className="text-sm font-medium text-gray-900">{promotion.title}</div>
                            <div className="text-sm text-gray-500">{promotion.category}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{promotion.discount}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <code className="promo-code">{promotion.code}</code>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          {formatDate(promotion.startDate)} - {formatDate(promotion.endDate)}
                        </div>
                        {promotion.url &&
                    <div className="text-xs text-blue-500 mt-1">
                            <a href={promotion.url} target="_blank" rel="noopener noreferrer">
                              <i className="fas fa-external-link-alt mr-1"></i> View URL
                            </a>
                          </div>
                    }
                      </td>

                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${promotion.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                          {promotion.status === 'active' ? 'Active' : 'Expired'}
                        </span>
                        {promotion.featured && (
                          <span className="ml-2 px-2 py-1 bg-yellow-200 text-yellow-800 text-xs rounded-full font-semibold inline-flex items-center">
                            <i className="fas fa-star mr-1"></i> Featured
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button
                      className="text-primary-color hover:text-primary-dark mr-3"
                      onClick={() => handleEdit(promotion)}>
                          <i className="fas fa-edit"></i> Edit
                        </button>
                        <button
                      className="text-red-500 hover:text-red-700"
                      onClick={() => handleDelete(promotion.id)}>
                          <i className="fas fa-trash-alt"></i> Delete
                        </button>
                      </td>
                    </tr>
                )}
                </tbody>
              </table>
            </div>
          }
        </div>
      </div>
      
      {/* Add/Edit Promotion Modal */}
      {isAddModalOpen &&
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl">
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold">
                  {editingPromotion ? 'Edit Promotion' : 'Add New Promotion'}
                </h2>
                <button
                className="text-gray-500 hover:text-gray-700"
                onClick={() => {
                  setIsAddModalOpen(false);
                  setEditingPromotion(null);
                }}>
                  <i className="fas fa-times text-xl"></i>
                </button>
              </div>
              
              <form onSubmit={handleSubmit}>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  <div className="col-span-2">
                    <label className="block text-sm font-medium mb-1">Promotion Title</label>
                    <input
                    type="text"
                    name="title"
                    value={formData.title}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    required />
                  </div>
                  
                  <div className="col-span-2">
                    <label className="block text-sm font-medium mb-1">Description</label>
                    <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    rows="3"
                    required>
                  </textarea>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-1">Discount</label>
                    <input
                    type="text"
                    name="discount"
                    value={formData.discount}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    placeholder="e.g. 20%, $50, BOGO"
                    required />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-1">Promotion Code</label>
                    <input
                    type="text"
                    name="code"
                    value={formData.code}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    required />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-1">Category</label>
                    <select
                    name="category"
                    value={formData.category}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    required>
                      <option value="fashion">Fashion</option>
                      <option value="electronics">Electronics</option>
                      <option value="travel">Travel</option>
                      <option value="health">Health & Wellness</option>
                      <option value="entertainment">Entertainment</option>
                      <option value="home">Home & Garden</option>
                      <option value="pets">Pets</option>
                      <option value="food">Food & Dining</option>
                      <option value="education">Education</option>
                    </select>
                  </div>
                  
                  <div className="col-span-2">
                    <label className="block text-sm font-medium mb-1">Promotion Image</label>
                    <div className="flex items-center space-x-4">
                      <div className="flex-1">
                        <input
                        type="file"
                        name="imageFile"
                        accept="image/*"
                        onChange={handleChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color" />
                      </div>
                      <div className="flex-1">
                        <input
                        type="text"
                        name="image"
                        value={formData.image}
                        onChange={handleChange}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                        placeholder="https://example.com/image.jpg" />
                      </div>
                    </div>
                    {(imagePreview || formData.image) &&
                  <div className="mt-2">
                        <img src={imagePreview || formData.image} alt="Preview" className="h-24 w-auto rounded-md object-cover" />
                      </div>
                  }
                  </div>
                  
                  <div className="col-span-2">
                    <label className="block text-sm font-medium mb-1">Promotion URL (for redirect)</label>
                    <input
                    type="url"
                    name="url"
                    value={formData.url}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    placeholder="https://example.com/promotion" />
                    <p className="text-xs text-gray-500 mt-1">Enter a valid URL starting with http:// or https://</p>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-1">Start Date</label>
                    <input
                    type="date"
                    name="startDate"
                    value={formData.startDate}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    required />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-1">End Date</label>
                    <input
                    type="date"
                    name="endDate"
                    value={formData.endDate}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                    required />
                  </div>
                </div>
                
                <div className="col-span-2 flex items-center mt-2">
                    <input
                      type="checkbox"
                      id="featured"
                      name="featured"
                      checked={formData.featured}
                      onChange={handleChange}
                      className="mr-2 h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded"
                    />
                    <label htmlFor="featured" className="text-sm font-medium select-none cursor-pointer">
                      Mark as Featured Deal (showcase on Home page)
                    </label>
                  </div>
                
                <div className="flex justify-end mt-4">
                  <button
                  type="button"
                  className="mr-2 px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                  onClick={() => {
                    setIsAddModalOpen(false);
                    setEditingPromotion(null);
                  }}>
                    Cancel
                  </button>
                  <button
                  type="submit"
                  className="px-4 py-2 bg-primary-color text-white rounded-md hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-color">
                    {editingPromotion ? 'Update Promotion' : 'Create Promotion'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      }
    </div>);
}