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
  const [isEditProfileModalOpen, setIsEditProfileModalOpen] = useState(false);
  const [editingPromotion, setEditingPromotion] = useState(null);
  const [merchantData, setMerchantData] = useState(null);

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
    featured: false, // Add featured field to form state
    originalPrice: '',
    discountedPrice: ''
  });

  // For image upload preview
  const [imagePreview, setImagePreview] = useState(null);
  const [logoPreview, setLogoPreview] = useState(null);

  // Form state for editing merchant profile
  const [profileFormData, setProfileFormData] = useState({
    name: '',
    profile: '', // description
    contactInfo: '', // email or main contact
    logo: '',
    address: '',
    contactNumber: '',
    socialMedia: {
      facebook: '',
      instagram: '',
      twitter: '',
      tiktok: ''
    },
    location: { // For GeoJSON Point
      type: 'Point',
      coordinates: [null, null] // [longitude, latitude]
    }
  });


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
    const fetchMerchantData = async (merchantId) => {
      try {
        const merchData = await window.API.Merchants.getById(merchantId);
        setMerchantData(merchData);
      } catch (err) {
        console.error('Error fetching merchant details:', err);
        setError('Failed to load merchant details.');
      }
    };

    const fetchPromotions = async (merchantId) => {
      try {
        let data = await window.API.Promotions.getByMerchant(merchantId);
        if (!Array.isArray(data)) {
          console.warn('Expected array of promotions, got:', data);
          data = [];
        }
        data = data.map(p => ({ ...p, id: p._id }));
        setPromotions(data);
      } catch (err) {
        console.error('Error fetching promotions:', err);
        setError('Failed to load promotions. Please try again later.');
      }
    };

    const loadDashboardData = async () => {
      setLoading(true);
      if (parsedUser.merchantId) {
        await fetchMerchantData(parsedUser.merchantId);
        await fetchPromotions(parsedUser.merchantId);
      } else {
        // This case should ideally not happen if role is 'merchant'
        // but if it does, the user might need to initialize their merchant profile.
        console.warn("Merchant user does not have a merchantId. Profile might need initialization.");
        setError("Merchant profile not fully initialized. Please contact support or try re-logging.");
        setPromotions([]);
      }
      setLoading(false);
    };

    loadDashboardData();
  }, [navigate]); // Added navigate to dependency array as per ESLint suggestion, though not strictly needed for this logic.

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
        featured: false, // Reset featured
        originalPrice: '',
        discountedPrice: ''
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
        featured: !!editingPromotion.featured, // Set featured from editing promotion
        originalPrice: editingPromotion.originalPrice || '',
        discountedPrice: editingPromotion.discountedPrice || ''
      });
      setImagePreview(editingPromotion.image || null);
      setIsAddModalOpen(true);
    }
  }, [editingPromotion]);

  // Populate profile form when merchantData is loaded or modal opens
  useEffect(() => {
    if (merchantData && isEditProfileModalOpen) {
      setProfileFormData({
        name: merchantData.name || '',
        profile: merchantData.profile || '',
        contactInfo: merchantData.contactInfo || '',
        logo: merchantData.logo || '',
        address: merchantData.address || '',
        contactNumber: merchantData.contactNumber || '',
        socialMedia: {
          facebook: merchantData.socialMedia?.facebook || '',
          instagram: merchantData.socialMedia?.instagram || '',
          twitter: merchantData.socialMedia?.twitter || '',
          tiktok: merchantData.socialMedia?.tiktok || ''
        },
        location: {
          type: 'Point',
          coordinates: merchantData.location?.coordinates || [null, null]
        }
      });
      setLogoPreview(merchantData.logo || null);
    }
  }, [merchantData, isEditProfileModalOpen]);


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

    // Validate prices if both are entered
    const originalPrice = parseFloat(formData.originalPrice);
    const discountedPrice = parseFloat(formData.discountedPrice);

    if (!isNaN(originalPrice) && !isNaN(discountedPrice) && discountedPrice >= originalPrice) {
      alert('Discounted price must be less than original price.');
      return;
    }

    if ((isNaN(originalPrice) && !isNaN(discountedPrice)) || (!isNaN(originalPrice) && isNaN(discountedPrice) && formData.discountedPrice !== '')) {
        // This condition means one is a number and the other is not (and not empty string for discounted)
        // Or if discountedPrice is an empty string but originalPrice is a number, that's fine.
        // We primarily care if one is filled and the other is not in a way that implies an incomplete pair.
        // However, the backend treats them as optional, so this might be overly strict here if they can be independent.
        // For now, let's allow them to be optional independently.
        // If they are both filled, the discountedPrice >= originalPrice check is the main one.
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
      return ['active', 'pending_approval', 'scheduled', 'approved'].includes(promo.status);
    } else if (activeTab === 'expired') {
      return ['expired', 'rejected', 'admin_paused'].includes(promo.status);
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

  const handleProfileInputChange = (e) => {
    const { name, value } = e.target;
    if (name.startsWith("socialMedia.")) {
      const field = name.split(".")[1];
      setProfileFormData(prev => ({
        ...prev,
        socialMedia: { ...prev.socialMedia, [field]: value }
      }));
    } else {
      setProfileFormData(prev => ({ ...prev, [name]: value }));
    }
  };

  const handleLocationChange = (newLocation) => {
    setProfileFormData(prev => ({
      ...prev,
      location: newLocation
    }));
  };

  const handleLogoFileChange = async (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = async () => {
        try {
          const optimizedImage = await window.optimizeImage(reader.result, 400, 0.8); // Optimize logo
          setProfileFormData(prev => ({ ...prev, logo: optimizedImage }));
          setLogoPreview(optimizedImage);
        } catch (error) {
          console.error('Error optimizing logo:', error);
          setProfileFormData(prev => ({ ...prev, logo: reader.result }));
          setLogoPreview(reader.result);
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const handleProfileFormSubmit = async (e) => {
    e.preventDefault();
    if (!user || !user.merchantId) {
      alert("Merchant ID not found. Cannot update profile.");
      return;
    }

    const dataToSubmit = { ...profileFormData };
    // Process location data before submission
    if (dataToSubmit.location && Array.isArray(dataToSubmit.location.coordinates)) {
      const [lon, lat] = dataToSubmit.location.coordinates;
      if (lon === null || lat === null) {
        // If either coordinate is null, treat it as "no location" to avoid validation errors.
        // The backend will not receive a 'location' field and will not attempt to update it.
        delete dataToSubmit.location;
      }
      // If both are valid numbers, the location object will be sent as is, which is correct.
    }

    try {
      setLoading(true);
      const updatedMerchant = await window.API.Merchants.update(user.merchantId, dataToSubmit);
      setMerchantData(updatedMerchant); // Update local state

      // Also update user.businessName in localStorage if it changed
      if (user.businessName !== updatedMerchant.name) {
        const storedUser = JSON.parse(localStorage.getItem('dealFinderUser'));
        storedUser.businessName = updatedMerchant.name;
        localStorage.setItem('dealFinderUser', JSON.stringify(storedUser));
        setUser(storedUser); // Update user state in dashboard
      }

      setIsEditProfileModalOpen(false);
      alert("Profile updated successfully!");
    } catch (err) {
      console.error("Error updating merchant profile:", err);
      alert("Failed to update profile. " + (err.message || "Please try again."));
    } finally {
      setLoading(false);
    }
  };


  if (loading) {
    return (
      <div className="page-container">
        <div className="container py-8">
          <div className="skeleton-card p-6 mb-4" style={{height:'80px'}}></div>
          <div className="skeleton-card p-6" style={{height:'400px'}}></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="page-container">
        <div className="container py-16 text-center">
          <div style={{fontSize:'3rem',marginBottom:'1rem'}}>😕</div>
          <h2 className="text-xl font-bold mb-2">Something went wrong</h2>
          <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>{error}</p>
          <button className="btn btn-primary" onClick={() => window.location.reload()}>Try Again</button>
        </div>
      </div>
    );
  }

  if (!user || !merchantData) {
    return (
      <div className="page-container">
        <div className="container py-16 text-center">
          <div style={{fontSize:'3rem',marginBottom:'1rem'}}>⚠️</div>
          <h2 className="text-xl font-bold mb-2">Merchant profile not found</h2>
          <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>Please re-login or contact support.</p>
          <button className="btn btn-primary" onClick={() => window.location.reload()}>Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Dashboard Header */}
      <div style={{background:'linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #f43f5e 100%)'}} className="py-10 mb-6">
        <div className="container">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div className="flex items-center gap-4">
              <div style={{width:'56px',height:'56px',borderRadius:'1rem',background:'rgba(255,255,255,0.2)',display:'flex',alignItems:'center',justifyContent:'center',fontSize:'1.5rem'}}>
                <i className="fas fa-store"></i>
              </div>
              <div>
                <h1 style={{color:'#fff',fontSize:'1.5rem',fontWeight:800,margin:0,letterSpacing:'-0.02em'}}>
                  {merchantData?.name || user?.businessName || 'Merchant Dashboard'}
                </h1>
                <p style={{color:'rgba(255,255,255,0.8)',fontSize:'0.875rem',margin:0}}>
                  {promotions.filter(p => ['active','approved'].includes(p.status)).length} active deals
                </p>
              </div>
            </div>
            <div className="flex gap-2">
              <button className="btn" onClick={() => setIsEditProfileModalOpen(true)}
                style={{background:'rgba(255,255,255,0.15)',color:'#fff',border:'1.5px solid rgba(255,255,255,0.3)',gap:'0.5rem'}}>
                <i className="fas fa-user-edit"></i> Edit Profile
              </button>
              <button className="btn" onClick={() => { setEditingPromotion(null); setIsAddModalOpen(true); }}
                style={{background:'#fff',color:'var(--primary-color)',fontWeight:700,gap:'0.5rem'}}>
                <i className="fas fa-plus"></i> Add Promotion
              </button>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mt-6">
            {[
              { label:'Total Deals', value: promotions.length, icon:'fa-tag' },
              { label:'Active', value: promotions.filter(p => ['active','approved'].includes(p.status)).length, icon:'fa-check-circle' },
              { label:'Pending', value: promotions.filter(p => p.status === 'pending_approval').length, icon:'fa-clock' },
              { label:'Total Clicks', value: filteredAnalyticsData.length, icon:'fa-mouse-pointer' }
            ].map(s => (
              <div key={s.label} style={{background:'rgba(255,255,255,0.15)',borderRadius:'0.875rem',padding:'0.875rem 1rem',backdropFilter:'blur(8px)'}}>
                <div style={{color:'rgba(255,255,255,0.7)',fontSize:'0.75rem',fontWeight:600,marginBottom:'0.25rem',textTransform:'uppercase',letterSpacing:'0.04em'}}>
                  <i className={`fas ${s.icon} mr-1`}></i>{s.label}
                </div>
                <div style={{color:'#fff',fontSize:'1.5rem',fontWeight:800}}>{s.value}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="container pb-8">
        {/* Tabs */}
        <div className="flex gap-1 mb-6 p-1 rounded-xl" style={{background:'var(--light-gray)',width:'fit-content'}}>
          {[['active','✅ Active'],['expired','⏰ Expired'],['all','📋 All'],['analytics','📊 Analytics']].map(([id, label]) => (
            <button key={id} onClick={() => setActiveTab(id)}
              style={{
                padding:'0.4rem 1rem', borderRadius:'0.625rem', fontSize:'0.85rem', fontWeight:600,
                border:'none', cursor:'pointer', transition:'all 0.2s',
                background: activeTab === id ? 'var(--card-bg)' : 'transparent',
                color: activeTab === id ? 'var(--primary-color)' : 'var(--text-secondary)',
                boxShadow: activeTab === id ? 'var(--box-shadow)' : 'none'
              }}>{label}</button>
          ))}
        </div>
          
        {activeTab === 'analytics' ?
            <div className="promotion-card p-6">
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
          <div className="text-center py-16">
              <div style={{fontSize:'3rem',marginBottom:'1rem'}}>🏷️</div>
              <h2 className="text-xl font-bold mb-2">No {activeTab !== 'all' ? activeTab : ''} promotions yet</h2>
              <p style={{color:'var(--text-secondary)',marginBottom:'1.5rem'}}>Create your first promotion to start attracting customers</p>
              <button className="btn btn-primary" style={{gap:'0.5rem'}}
                onClick={() => { setEditingPromotion(null); setIsAddModalOpen(true); }}>
                <i className="fas fa-plus"></i> Create Promotion
              </button>
            </div> :

          <div className="promotion-card overflow-hidden">
              <div className="overflow-x-auto">
              <table className="w-full" style={{borderCollapse:'collapse'}}>
                <thead>
                  <tr style={{background:'var(--light-gray)',borderBottom:'1.5px solid var(--border-color)'}}>
                    <th className="px-5 py-3 text-left" style={{fontSize:'0.75rem',fontWeight:700,color:'var(--text-secondary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Promotion</th>
                    <th className="px-5 py-3 text-left" style={{fontSize:'0.75rem',fontWeight:700,color:'var(--text-secondary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Discount</th>
                    <th className="px-5 py-3 text-left" style={{fontSize:'0.75rem',fontWeight:700,color:'var(--text-secondary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Code</th>
                    <th className="px-5 py-3 text-left" style={{fontSize:'0.75rem',fontWeight:700,color:'var(--text-secondary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Dates</th>
                    <th className="px-5 py-3 text-left" style={{fontSize:'0.75rem',fontWeight:700,color:'var(--text-secondary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Status</th>
                    <th className="px-5 py-3 text-right" style={{fontSize:'0.75rem',fontWeight:700,color:'var(--text-secondary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredPromotions.map((promotion) =>
                    <tr key={promotion.id} style={{borderBottom:'1px solid var(--border-color)',transition:'background 0.15s'}}
                      onMouseEnter={e => e.currentTarget.style.background='var(--light-gray)'}
                      onMouseLeave={e => e.currentTarget.style.background='transparent'}>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-3">
                          {promotion.image && (
                            <img src={promotion.image} alt={promotion.title}
                              style={{width:'40px',height:'40px',borderRadius:'0.5rem',objectFit:'cover',flexShrink:0,border:'1px solid var(--border-color)'}} />
                          )}
                          <div>
                            <div style={{fontWeight:600,fontSize:'0.875rem',color:'var(--text-primary)'}}>{promotion.title}</div>
                            <div style={{fontSize:'0.75rem',color:'var(--text-secondary)'}}>{promotion.category}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-3">
                        <span className="discount-badge" style={{position:'static',fontSize:'0.75rem'}}>{promotion.discount} OFF</span>
                      </td>
                      <td className="px-5 py-3">
                        <code className="promo-code" style={{fontSize:'0.8rem'}}>{promotion.code}</code>
                      </td>
                      <td className="px-5 py-3">
                        <div style={{fontSize:'0.8rem',color:'var(--text-secondary)'}}>
                          {formatDate(promotion.startDate)}<br/>{formatDate(promotion.endDate)}
                        </div>
                        {promotion.url && (
                          <a href={promotion.url} target="_blank" rel="noopener noreferrer"
                            style={{fontSize:'0.72rem',color:'var(--primary-color)',display:'flex',alignItems:'center',gap:'0.25rem',marginTop:'0.25rem'}}>
                            <i className="fas fa-external-link-alt"></i> View URL
                          </a>
                        )}
                      </td>
                      <td className="px-5 py-3">
                        <span style={{
                          padding:'0.2rem 0.6rem', borderRadius:'9999px', fontSize:'0.72rem', fontWeight:700,
                          background: promotion.status === 'active' || promotion.status === 'approved' ? 'rgba(16,185,129,0.1)' :
                            promotion.status === 'pending_approval' ? 'rgba(245,158,11,0.1)' :
                            promotion.status === 'scheduled' ? 'rgba(99,102,241,0.1)' :
                            promotion.status === 'rejected' ? 'rgba(239,68,68,0.1)' : 'rgba(100,116,139,0.1)',
                          color: promotion.status === 'active' || promotion.status === 'approved' ? '#059669' :
                            promotion.status === 'pending_approval' ? '#d97706' :
                            promotion.status === 'scheduled' ? '#6366f1' :
                            promotion.status === 'rejected' ? '#ef4444' : '#64748b'
                        }}>
                          {promotion.status ? promotion.status.replace(/_/g,' ').replace(/\b\w/g,l=>l.toUpperCase()) : 'Expired'}
                        </span>
                        {promotion.featured && (
                          <span style={{display:'block',marginTop:'0.25rem',fontSize:'0.7rem',fontWeight:700,color:'#d97706'}}>⭐ Featured</span>
                        )}
                      </td>
                      <td className="px-5 py-3 text-right">
                        <div className="flex justify-end gap-2">
                          <button onClick={() => handleEdit(promotion)}
                            style={{padding:'0.3rem 0.75rem',borderRadius:'0.5rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--primary-color)',fontSize:'0.8rem',fontWeight:600,cursor:'pointer',gap:'0.3rem',display:'flex',alignItems:'center'}}>
                            <i className="fas fa-edit"></i> Edit
                          </button>
                          <button onClick={() => handleDelete(promotion.id)}
                            style={{padding:'0.3rem 0.75rem',borderRadius:'0.5rem',border:'1.5px solid rgba(239,68,68,0.3)',background:'rgba(239,68,68,0.06)',color:'#ef4444',fontSize:'0.8rem',fontWeight:600,cursor:'pointer',gap:'0.3rem',display:'flex',alignItems:'center'}}>
                            <i className="fas fa-trash-alt"></i>
                          </button>
                        </div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
            </div>
        }
      </div>
    </div>
      
      {/* Edit Merchant Profile Modal */}
      {isEditProfileModalOpen && merchantData && (
      <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.6)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:50,padding:'1rem',overflowY:'auto',backdropFilter:'blur(4px)'}}>
        <div style={{background:'var(--card-bg)',borderRadius:'1.25rem',width:'100%',maxWidth:'640px',maxHeight:'90vh',overflowY:'auto',boxShadow:'0 24px 64px rgba(0,0,0,0.3)'}}>
          <div style={{padding:'1.5rem',borderBottom:'1px solid var(--border-color)',display:'flex',justifyContent:'space-between',alignItems:'center',position:'sticky',top:0,background:'var(--card-bg)',zIndex:1,borderRadius:'1.25rem 1.25rem 0 0'}}>
            <div>
              <h2 style={{fontSize:'1.25rem',fontWeight:800,color:'var(--text-primary)',margin:0}}>Edit Store Profile</h2>
              <p style={{fontSize:'0.8rem',color:'var(--text-secondary)',margin:0}}>Update your store information</p>
            </div>
            <button onClick={() => setIsEditProfileModalOpen(false)}
              style={{width:'32px',height:'32px',borderRadius:'50%',border:'1.5px solid var(--border-color)',background:'var(--light-gray)',cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center',color:'var(--text-secondary)'}}>
              <i className="fas fa-times"></i>
            </button>
          </div>
          <div style={{padding:'1.5rem'}}>
            <form onSubmit={handleProfileFormSubmit}>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div className="md:col-span-2">
                  <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Business Name *</label>
                  <input type="text" name="name" value={profileFormData.name} onChange={handleProfileInputChange} required
                    style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                </div>
                <div className="md:col-span-2">
                  <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Description</label>
                  <textarea name="profile" value={profileFormData.profile} onChange={handleProfileInputChange} rows="3"
                    style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',resize:'vertical',boxSizing:'border-box'}}></textarea>
                </div>
                <div>
                  <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Contact Email/Phone</label>
                  <input type="text" name="contactInfo" value={profileFormData.contactInfo} onChange={handleProfileInputChange}
                    style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                </div>
                <div>
                  <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Contact Number</label>
                  <input type="tel" name="contactNumber" value={profileFormData.contactNumber} onChange={handleProfileInputChange}
                    style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                </div>
                <div className="md:col-span-2">
                  <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Address</label>
                  <input type="text" name="address" value={profileFormData.address} onChange={handleProfileInputChange}
                    style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                </div>
                <LocationPicker location={profileFormData.location} onLocationChange={handleLocationChange} />
                {/* Logo */}
                <div className="md:col-span-2">
                  <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.5rem',color:'var(--text-primary)'}}>Store Logo</label>
                  <div style={{display:'flex',alignItems:'center',gap:'1rem',padding:'1rem',borderRadius:'0.875rem',border:'1.5px solid var(--border-color)',background:'var(--light-gray)'}}>
                    {(logoPreview || profileFormData.logo) && (
                      <img src={logoPreview || profileFormData.logo} alt="Logo" style={{width:'56px',height:'56px',borderRadius:'50%',objectFit:'cover',border:'2px solid var(--primary-color)',flexShrink:0}} />
                    )}
                    <div className="flex-1">
                      <input type="file" accept="image/*" onChange={handleLogoFileChange} style={{fontSize:'0.8rem',color:'var(--text-secondary)',width:'100%'}} />
                      <input type="text" name="logo" value={profileFormData.logo} onChange={handleProfileInputChange} placeholder="Or paste image URL"
                        style={{width:'100%',padding:'0.5rem 0.75rem',borderRadius:'0.5rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.8rem',outline:'none',marginTop:'0.5rem',boxSizing:'border-box'}} />
                    </div>
                  </div>
                </div>
                {/* Social Media */}
                <div className="md:col-span-2">
                  <p style={{fontSize:'0.875rem',fontWeight:700,color:'var(--text-primary)',marginBottom:'0.75rem'}}>Social Media</p>
                  <div className="grid grid-cols-2 gap-3">
                    {Object.keys(profileFormData.socialMedia).map(key => (
                      <div key={key}>
                        <label style={{display:'block',fontSize:'0.8rem',fontWeight:600,marginBottom:'0.3rem',color:'var(--text-secondary)',textTransform:'capitalize'}}>
                          <i className={`fab fa-${key} mr-1`}></i>{key}
                        </label>
                        <input type="text" name={`socialMedia.${key}`} value={profileFormData.socialMedia[key]} onChange={handleProfileInputChange}
                          placeholder={`@your${key}`}
                          style={{width:'100%',padding:'0.6rem 0.875rem',borderRadius:'0.5rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.85rem',outline:'none',boxSizing:'border-box'}} />
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              <div className="flex justify-end gap-3 mt-2">
                <button type="button" onClick={() => setIsEditProfileModalOpen(false)}
                  style={{padding:'0.6rem 1.25rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-secondary)',fontWeight:600,cursor:'pointer',fontSize:'0.875rem'}}>
                  Cancel
                </button>
                <button type="submit" disabled={loading} className="btn btn-primary" style={{gap:'0.5rem'}}>
                  {loading ? <><i className="fas fa-spinner fa-spin"></i> Saving...</> : <><i className="fas fa-save"></i> Save Profile</>}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
      )}

      {/* Add/Edit Promotion Modal */}
      {isAddModalOpen &&
      <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.6)',display:'flex',alignItems:'center',justifyContent:'center',zIndex:50,padding:'1rem',overflowY:'auto',backdropFilter:'blur(4px)'}}>
          <div style={{background:'var(--card-bg)',borderRadius:'1.25rem',width:'100%',maxWidth:'640px',maxHeight:'90vh',overflowY:'auto',boxShadow:'0 24px 64px rgba(0,0,0,0.3)'}}>
            <div style={{padding:'1.5rem',borderBottom:'1px solid var(--border-color)',display:'flex',justifyContent:'space-between',alignItems:'center',position:'sticky',top:0,background:'var(--card-bg)',zIndex:1,borderRadius:'1.25rem 1.25rem 0 0'}}>
              <div>
                <h2 style={{fontSize:'1.25rem',fontWeight:800,color:'var(--text-primary)',margin:0}}>
                  {editingPromotion ? 'Edit Promotion' : 'New Promotion'}
                </h2>
                <p style={{fontSize:'0.8rem',color:'var(--text-secondary)',margin:0}}>
                  {editingPromotion ? 'Update promotion details' : 'Fill in the details below'}
                </p>
              </div>
              <button onClick={() => { setIsAddModalOpen(false); setEditingPromotion(null); }}
                style={{width:'32px',height:'32px',borderRadius:'50%',border:'1.5px solid var(--border-color)',background:'var(--light-gray)',cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center',color:'var(--text-secondary)'}}>
                <i className="fas fa-times"></i>
              </button>
            </div>
            <div style={{padding:'1.5rem'}}>
              <form onSubmit={handleSubmit}>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                  {[['col-span-2','text','title','Promotion Title *','e.g. Summer Sale 20% Off',true],
                    ['','text','discount','Discount *','e.g. 20%, $50, BOGO',true],
                    ['','text','code','Promo Code *','e.g. SUMMER20',true],
                    ['','number','originalPrice','Original Price','e.g. 100.00',false],
                    ['','number','discountedPrice','Discounted Price','e.g. 80.00',false],
                  ].map(([span, type, name, label, placeholder, required]) => (
                    <div key={name} className={span}>
                      <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>{label}</label>
                      <input type={type} name={name} value={formData[name]} onChange={handleChange} placeholder={placeholder} required={required}
                        step={type === 'number' ? '0.01' : undefined}
                        style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                    </div>
                  ))}

                  <div className="col-span-2">
                    <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Description *</label>
                    <textarea name="description" value={formData.description} onChange={handleChange} rows="3" required
                      style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',resize:'vertical',boxSizing:'border-box'}}></textarea>
                  </div>

                  <div>
                    <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Category *</label>
                    <select name="category" value={formData.category} onChange={handleChange} required
                      style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}}>
                      {['fashion','electronics','travel','health','entertainment','home','pets','food','education'].map(c => (
                        <option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Start Date *</label>
                    <input type="date" name="startDate" value={formData.startDate} onChange={handleChange} required
                      style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                  </div>

                  <div>
                    <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>End Date *</label>
                    <input type="date" name="endDate" value={formData.endDate} onChange={handleChange} required
                      style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                  </div>

                  <div className="col-span-2">
                    <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.5rem',color:'var(--text-primary)'}}>Promotion Image</label>
                    <div style={{padding:'1rem',borderRadius:'0.875rem',border:'1.5px solid var(--border-color)',background:'var(--light-gray)'}}>
                      <div className="flex gap-3 flex-wrap">
                        <input type="file" name="imageFile" accept="image/*" onChange={handleChange} style={{fontSize:'0.8rem',color:'var(--text-secondary)',flex:1}} />
                        <input type="text" name="image" value={formData.image} onChange={handleChange} placeholder="Or paste image URL"
                          style={{flex:1,padding:'0.5rem 0.75rem',borderRadius:'0.5rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.8rem',outline:'none',minWidth:'160px'}} />
                      </div>
                      {(imagePreview || formData.image) && (
                        <img src={imagePreview || formData.image} alt="Preview" style={{height:'80px',borderRadius:'0.5rem',objectFit:'cover',marginTop:'0.75rem',border:'1px solid var(--border-color)'}} />
                      )}
                    </div>
                  </div>

                  <div className="col-span-2">
                    <label style={{display:'block',fontSize:'0.85rem',fontWeight:600,marginBottom:'0.4rem',color:'var(--text-primary)'}}>Promotion URL</label>
                    <input type="url" name="url" value={formData.url} onChange={handleChange} placeholder="https://yourstore.com/deal"
                      style={{width:'100%',padding:'0.7rem 1rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-primary)',fontSize:'0.9rem',outline:'none',boxSizing:'border-box'}} />
                  </div>

                  <div className="col-span-2">
                    <label style={{display:'flex',alignItems:'center',gap:'0.75rem',padding:'0.875rem',borderRadius:'0.75rem',border:'1.5px solid var(--border-color)',cursor:'pointer',background:'var(--card-bg)'}}>
                      <input type="checkbox" name="featured" checked={formData.featured} onChange={handleChange}
                        style={{width:'16px',height:'16px',accentColor:'var(--primary-color)',cursor:'pointer'}} />
                      <div>
                        <span style={{fontSize:'0.875rem',fontWeight:600,color:'var(--text-primary)'}}>⭐ Mark as Featured Deal</span>
                        <p style={{fontSize:'0.75rem',color:'var(--text-secondary)',margin:0}}>Featured deals appear on the homepage</p>
                      </div>
                    </label>
                  </div>
                </div>

                <div className="flex justify-end gap-3">
                  <button type="button" onClick={() => { setIsAddModalOpen(false); setEditingPromotion(null); }}
                    style={{padding:'0.6rem 1.25rem',borderRadius:'0.625rem',border:'1.5px solid var(--border-color)',background:'var(--card-bg)',color:'var(--text-secondary)',fontWeight:600,cursor:'pointer',fontSize:'0.875rem'}}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-primary" style={{gap:'0.5rem'}}>
                    <i className={`fas ${editingPromotion ? 'fa-save' : 'fa-plus'}`}></i>
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

window.MerchantDashboard = MerchantDashboard;