function UserProfile() {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [activeTab, setActiveTab] = useState('profile');
  const [loading, setLoading] = useState(true);
  const [savedPromotions, setSavedPromotions] = useState([]);
  const [followedMerchants, setFollowedMerchants] = useState([]);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [imageFile, setImageFile] = useState(null);
  const [imageKey, setImageKey] = useState(Date.now());

  // Form state
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    businessName: '',
    profile: '',
    contactInfo: '',
    logo: '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
    notifications: {
      email: true,
      expiringDeals: true,
      favoriteStores: true,
      recommendations: true
    },
    profilePicture: '',
    address: '',
    contactNumber: '',
    facebook: '',
    instagram: '',
    twitter: '',
    tiktok: '',
    locationLat: '',
    locationLng: ''
  });

  useEffect(() => {
    try {
      // Check if user is logged in
      const userData = localStorage.getItem('dealFinderUser');
      if (!userData) {
        navigate('/login');
        return;
      }
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      setImageKey(Date.now());
      setFormData(prevData => ({
        ...prevData,
        name: parsedUser.name || '',
        email: parsedUser.email || '',
        profilePicture: parsedUser.profilePicture || '',
        notifications: {
          ...prevData.notifications,
          ...(parsedUser.preferences?.notifications || {})
        }
      }));
      if (parsedUser.role === 'merchant' && parsedUser.merchantId) {
        fetchMerchantDetails(parsedUser.merchantId);
      } else {
        setLoading(false);
      }
      // Load user's saved promotions from backend
      window.API.Users.getFavorites(parsedUser._id).then(favorites => {
        favorites = favorites.map(p => ({ ...p, id: p.id || p._id }));
        setSavedPromotions(favorites);
      });
      // Load followed merchants from localStorage (real data only)
      let following = [];
      try {
        following = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
        following = following.map(m => ({ ...m, id: m.id || m._id }));
      } catch {}
      setFollowedMerchants(following);
    } catch (err) {
      console.error("Error in UserProfile initialization:", err);
      setError("Failed to load profile. Please try again.");
      setLoading(false);
    }
  }, []);

  const fetchMerchantDetails = async (merchantId) => {
    try {
      if (!merchantId) {
        console.error('No merchant ID provided');
        setError('Failed to load merchant details: Missing merchant ID');
        setLoading(false);
        return;
      }
      
      // Then fetch merchant data
      const merchantData = await window.API.Merchants.getById(merchantId);
      
      if (merchantData) {
        // Update image key if logo is present
        if (merchantData.logo) {
          setImageKey(Date.now());
          console.log("Merchant logo found:", merchantData.logo.substring(0, 50) + "...");
        }
        
        setFormData(prevData => ({
          ...prevData,
          businessName: merchantData.name || '',
          profile: merchantData.profile || '',
          contactInfo: merchantData.contactInfo || '',
          logo: merchantData.logo || '',
          address: merchantData.address || '',
          contactNumber: merchantData.contactNumber || '',
          facebook: merchantData.socialMedia?.facebook || '',
          instagram: merchantData.socialMedia?.instagram || '',
          twitter: merchantData.socialMedia?.twitter || '',
          tiktok: merchantData.socialMedia?.tiktok || '',
          locationLat: merchantData.location?.lat || '',
          locationLng: merchantData.location?.lng || ''
        }));
      } else {
        console.warn('No merchant data returned from API');
      }
    } catch (err) {
      console.error('Error fetching merchant details:', err);
      setError('Failed to load merchant details. Please try again.');
      // Still allow the user to edit their basic profile even if merchant details fail
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleNotificationChange = (e) => {
    const { name, checked } = e.target;
    setFormData({
      ...formData,
      notifications: {
        ...formData.notifications,
        [name]: checked
      }
    });
  };

  const handleProfileSubmit = async (e) => {
    e.preventDefault();
    setSuccess('');
    setError('');
    
    try {
      if (!user || !user._id) {
        setError('User information is missing. Please try logging in again.');
        return;
      }
      
      // Generate a new image key to ensure fresh rendering
      setImageKey(Date.now());
      
      // Validate image size if it's a base64 string (uploaded file)
      if (formData.logo && formData.logo.startsWith('data:image')) {
        // Rough estimation of base64 size: 4/3 of the string length
        const sizeInBytes = Math.round((formData.logo.length * 3) / 4);
        const sizeInMB = sizeInBytes / (1024 * 1024);
        
        console.log("Submitting image, size:", sizeInMB.toFixed(2), "MB");
        
        if (sizeInMB > 2) {
          setError('Logo image is too large. Maximum size is 2MB.');
          return;
        }
      }
      
      // Prepare data for API
      const profileData = {
        name: formData.name,
        email: formData.email,
        logo: formData.logo, // Always include logo in user profile
        businessName: user.role === 'merchant' ? formData.businessName : undefined,
        profilePicture: formData.profilePicture // Include profile picture
      };
      
      // Update user profile
      const updatedUser = await window.API.Users.updateProfile(user._id, profileData);
      
      // If user is a merchant, update merchant profile too
      if (user.role === 'merchant' && user.merchantId) {
        const merchantData = {
          name: formData.businessName,
          profile: formData.profile,
          contactInfo: formData.contactInfo,
          logo: formData.logo,
          address: formData.address,
          contactNumber: formData.contactNumber,
          socialMedia: formData.socialMedia,
          location: {
            lat: formData.locationLat,
            lng: formData.locationLng
          }
        };
        
        try {
          await window.API.Merchants.update(user.merchantId, merchantData);
        } catch (merchantErr) {
          console.error('Error updating merchant profile:', merchantErr);
          // Continue with user profile update even if merchant update fails
          setError('Your profile was updated, but there was an issue updating your merchant details.');
        }
      }
      
      // Update local storage and state with new logo (for all users)
      const updatedUserData = {
        ...user,
        ...updatedUser,
        logo: formData.logo,
        preferences: {
          ...user.preferences,
          notifications: formData.notifications
        },
        profilePicture: formData.profilePicture // Update profile picture in local storage
      };
      localStorage.setItem('dealFinderUser', JSON.stringify(updatedUserData));
      setUser(updatedUserData);
      
      // Show success message (only if there's no error)
      if (!error) {
        setSuccess('Profile updated successfully!');
      }
    } catch (err) {
      console.error('Error updating profile:', err);
      setError('Failed to update profile. Please try again.');
    }
  };

  const handlePasswordSubmit = (e) => {
    e.preventDefault();
    setSuccess('');
    setError('');

    // Validate passwords
    if (formData.newPassword !== formData.confirmPassword) {
      setError('New passwords do not match!');
      return;
    }

    // In a real app, this would make an API call to update the password

    // Reset password fields
    setFormData({
      ...formData,
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    });

    // Show success message
    setSuccess('Password updated successfully!');
  };

  const handleFavoriteToggle = async (promotionId) => {
    // Remove from favorites via backend
    if (!user || !user._id) return;
    try {
      await window.API.Users.removeFavorite(user._id, promotionId);
      setSavedPromotions((prevPromotions) =>
        prevPromotions.filter((promo) => promo.id !== promotionId)
      );
    } catch (err) {
      console.error('Failed to remove favorite:', err);
    }
  };

  const handleUnfollowMerchant = (merchantId) => {
    // In a real app, this would make an API call
    setFollowedMerchants((prevMerchants) =>
    prevMerchants.filter((merchant) => merchant.id !== merchantId)
    );
  };

  // Utility to get a safe logo image (base64, URL, or fallback)
  function getSafeLogo(logo, name) {
    if (logo && typeof logo === 'string') {
      if (logo.startsWith('data:image')) return logo;
      if (logo.startsWith('http')) return logo;
    }
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;
  }

  // Utility to get a safe profile image (base64, URL, or fallback)
  function getSafeProfileImage(profilePicture, name) {
    if (profilePicture && typeof profilePicture === 'string') {
      if (profilePicture.startsWith('data:image')) return profilePicture;
      if (profilePicture.startsWith('http')) return profilePicture;
    }
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'U')}&background=random&size=300`;
  }

  if (loading) {
    return (
      <div className="page-container">
        <div className="container py-8 text-center">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
        </div>
      </div>);
  }

  return (
    <div className="page-container">
      <div className="container py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {/* Sidebar */}
          <div className="md:col-span-1">
            <div className="bg-white rounded-lg shadow-md p-6">
              <div className="flex flex-col items-center mb-6">
                <div className="w-20 h-20 bg-primary-color rounded-full flex items-center justify-center text-white text-2xl font-bold mb-2 overflow-hidden">
                  <img
                    src={getSafeProfileImage(formData.profilePicture, user.name)}
                    alt="Profile"
                    className="w-full h-full object-cover"
                    onError={e => {
                      e.target.onerror = null;
                      e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random&size=300`;
                    }}
                  />
                </div>
                <h2 className="text-xl font-bold">{user.name}</h2>
                <p className="text-gray-500">{user.email}</p>
                {user.role === 'merchant' && (
                  <span className="mt-1 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-xs">
                    Merchant Account
                  </span>
                )}
              </div>
              
              <nav>
                <button
                  className={`w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'profile' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`}
                  onClick={() => setActiveTab('profile')}>
                  <i className="fas fa-user-circle mr-2"></i> Profile Settings
                </button>
                <button
                  className={`w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'security' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`}
                  onClick={() => setActiveTab('security')}>
                  <i className="fas fa-lock mr-2"></i> Security
                </button>
                <button
                  className={`w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'notifications' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`}
                  onClick={() => setActiveTab('notifications')}>
                  <i className="fas fa-bell mr-2"></i> Notifications
                </button>
                <button
                  className={`w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'favorites' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`}
                  onClick={() => setActiveTab('favorites')}>
                  <i className="fas fa-heart mr-2"></i> My Favorites
                </button>
                <button
                  className={`w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'following' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`}
                  onClick={() => setActiveTab('following')}>
                  <i className="fas fa-store mr-2"></i> Following
                </button>
                
                {user.role === 'merchant' && (
                  <button
                    className={`w-full text-left py-2 px-4 rounded-md mb-1 flex items-center hover:bg-gray-100`}
                    onClick={() => navigate('/merchant/dashboard')}>
                    <i className="fas fa-chart-line mr-2"></i> Merchant Dashboard
                  </button>
                )}
                
                <hr className="my-4" />
                <button
                  className="w-full text-left py-2 px-4 rounded-md mb-1 flex items-center text-red-500 hover:bg-red-50"
                  onClick={() => {
                    localStorage.removeItem('dealFinderUser');
                    navigate('/login');
                  }}>
                  <i className="fas fa-sign-out-alt mr-2"></i> Logout
                </button>
              </nav>
            </div>
          </div>
          
          {/* Main Content */}
          <div className="md:col-span-3">
            <div className="bg-white rounded-lg shadow-md p-6">
              {success && (
                <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
                  {success}
                </div>
              )}
              
              {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                  {error}
                </div>
              )}
              
              {/* Profile Settings */}
              {activeTab === 'profile' &&
              <div>
                  <h1 className="text-2xl font-bold mb-6">Profile Settings</h1>
                  
                  <form onSubmit={handleProfileSubmit}>
                    <div className="mb-4">
                      <label className="block text-sm font-medium mb-1">Full Name</label>
                      <input
                      type="text"
                      name="name"
                      value={formData.name}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                      required />
                    </div>
                    
                    <div className="mb-4">
                      <label className="block text-sm font-medium mb-1">Email Address</label>
                      <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                      required
                      disabled />
                      <p className="text-sm text-gray-500 mt-1">Email cannot be changed</p>
                    </div>
                    
                    {user.role === 'merchant' && (
                      <>
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Business Name</label>
                          <input
                            type="text"
                            name="businessName"
                            value={formData.businessName}
                            onChange={handleInputChange}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                            required
                          />
                        </div>
                        
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Business Profile</label>
                          <textarea
                            name="profile"
                            value={formData.profile}
                            onChange={handleInputChange}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                            rows="3"
                          ></textarea>
                          <p className="text-sm text-gray-500 mt-1">Describe your business in a few sentences</p>
                        </div>
                        
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Contact Information</label>
                          <input
                            type="text"
                            name="contactInfo"
                            value={formData.contactInfo}
                            onChange={handleInputChange}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                          />
                          <p className="text-sm text-gray-500 mt-1">Phone number or additional email</p>
                        </div>
                        
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Business Logo</label>
                          
                          <div className="flex items-center space-x-4 mb-2">
                            <div className="w-16 h-16 bg-gray-200 rounded-full overflow-hidden flex-shrink-0">
                              <img
                                key={imageKey}
                                src={getSafeLogo(formData.logo, formData.businessName || user?.name)}
                                alt="Logo Preview"
                                className="w-full h-full object-cover logo-preview-img"
                                onError={(e) => {
                                  e.target.onerror = null;
                                  e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(formData.businessName || user?.name || 'M')}&background=random&size=300`;
                                }}
                              />
                            </div>
                            
                            <div className="flex-grow">
                              <input
                                type="text"
                                name="logo"
                                value={formData.logo}
                                onChange={handleInputChange}
                                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                                placeholder="https://example.com/logo.jpg"
                              />
                              <p className="text-sm text-gray-500 mt-1">Enter a URL for your business logo</p>
                            </div>
                          </div>
                          
                          <div className="mt-2">
                            <label className="block text-sm font-medium mb-1">Or upload an image:</label>
                            <input
                              type="file"
                              accept="image/jpeg,image/png,image/gif"
                              onChange={(e) => {
                                const file = e.target.files[0];
                                if (file) {
                                  // Check file size (max 2MB)
                                  if (file.size > 2 * 1024 * 1024) {
                                    setError('Image file is too large. Maximum size is 2MB.');
                                    e.target.value = ''; // Clear the file input
                                    return;
                                  }
                                  
                                  // Convert to base64 for preview
                                  const reader = new FileReader();
                                  reader.onloadend = () => {
                                    const imageData = reader.result;
                                    console.log("Image loaded, length:", imageData.length);
                                    
                                    // Generate a new image key to force re-render
                                    const newImageKey = Date.now();
                                    setImageKey(newImageKey);
                                    
                                    // Update the form data with the new image
                                    setFormData(prevState => ({
                                      ...prevState,
                                      logo: imageData
                                    }));
                                    
                                    setSuccess('Image uploaded successfully. Click "Save Changes" to update your profile.');
                                    
                                    // Force browser to re-render the image
                                    setTimeout(() => {
                                      const imgElement = document.querySelector('.logo-preview-img');
                                      if (imgElement) {
                                        imgElement.src = imageData;
                                      }
                                    }, 50);
                                  };
                                  reader.onerror = () => {
                                    setError('Failed to read the image file. Please try again.');
                                  };
                                  reader.readAsDataURL(file);
                                }
                              }}
                              className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary-color file:text-white hover:file:bg-primary-dark"
                            />
                            <p className="text-xs text-gray-500 mt-1">Max file size: 2MB. Supported formats: JPG, PNG, GIF</p>
                          </div>
                        </div>
                        
                        {/* New fields for merchant details */}
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Business Address</label>
                          <input
                            type="text"
                            name="address"
                            value={formData.address}
                            onChange={handleInputChange}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                            placeholder="Enter your business address"
                          />
                        </div>
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Contact Number</label>
                          <input
                            type="text"
                            name="contactNumber"
                            value={formData.contactNumber}
                            onChange={handleInputChange}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                            placeholder="Enter your contact number"
                          />
                        </div>
                        
                        {/* Social Media Section */}
                        <div className="mb-4">
                          <label className="block text-sm font-medium mb-1">Social Media Profiles</label>
                          <div className="space-y-2">
                            {/* List of added social media accounts */}
                            {Object.entries(formData.socialMedia || {}).filter(([platform, username]) => username).map(([platform, username]) => (
                              <div key={platform} className="flex items-center gap-2 bg-gray-50 px-3 py-2 rounded">
                                <span className="capitalize font-medium"><i className={`fab fa-${platform} mr-1`}></i>{platform}</span>
                                <span className="text-gray-700">{username}</span>
                                <button type="button" className="ml-2 text-red-500 hover:text-red-700" onClick={() => {
                                  setFormData(prev => ({
                                    ...prev,
                                    socialMedia: { ...prev.socialMedia, [platform]: '' }
                                  }));
                                }}>
                                  <i className="fas fa-times"></i>
                                </button>
                              </div>
                            ))}
                          </div>
                          {/* Add Social Media UI */}
                          <div className="flex items-center gap-2 mt-2">
                            <select
                              value={formData._newSocialPlatform || ''}
                              onChange={e => setFormData(prev => ({ ...prev, _newSocialPlatform: e.target.value }))}
                              className="px-2 py-1 border rounded"
                            >
                              <option value="">Select Platform</option>
                              {['facebook', 'instagram', 'twitter', 'tiktok'].filter(p => !(formData.socialMedia && formData.socialMedia[p])).map(platform => (
                                <option key={platform} value={platform}>{platform.charAt(0).toUpperCase() + platform.slice(1)}</option>
                              ))}
                            </select>
                            <input
                              type="text"
                              placeholder="Username"
                              value={formData._newSocialUsername || ''}
                              onChange={e => setFormData(prev => ({ ...prev, _newSocialUsername: e.target.value }))}
                              className="px-2 py-1 border rounded"
                            />
                            <button
                              type="button"
                              className="btn btn-primary px-3 py-1"
                              disabled={!(formData._newSocialPlatform && formData._newSocialUsername)}
                              onClick={() => {
                                if (formData._newSocialPlatform && formData._newSocialUsername) {
                                  setFormData(prev => ({
                                    ...prev,
                                    socialMedia: {
                                      ...prev.socialMedia,
                                      [formData._newSocialPlatform]: formData._newSocialUsername
                                    },
                                    _newSocialPlatform: '',
                                    _newSocialUsername: ''
                                  }));
                                }
                              }}
                            >Add</button>
                          </div>
                          <p className="text-xs text-gray-500 mt-1">Add only your active social media accounts. You can remove or edit them anytime.</p>
                        </div>
                      </>
                    )}
                    
                    {/* Profile Picture Upload */}
                    <div className="mb-4">
                      <label className="block text-sm font-medium mb-1">Profile Picture</label>
                      <div className="flex items-center space-x-4 mb-2">
                        <div className="w-16 h-16 bg-gray-200 rounded-full overflow-hidden flex-shrink-0">
                          <img
                            src={getSafeProfileImage(formData.profilePicture, formData.name)}
                            alt="Profile Preview"
                            className="w-full h-full object-cover"
                            onError={e => {
                              e.target.onerror = null;
                              e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(formData.name)}&background=random&size=300`;
                            }}
                          />
                        </div>
                        <input
                          type="file"
                          accept="image/jpeg,image/png,image/gif"
                          onChange={e => {
                            const file = e.target.files[0];
                            if (file) {
                              if (file.size > 2 * 1024 * 1024) {
                                setError('Image file is too large. Maximum size is 2MB.');
                                e.target.value = '';
                                return;
                              }
                              const reader = new FileReader();
                              reader.onloadend = () => {
                                setFormData(prev => ({ ...prev, profilePicture: reader.result }));
                                setSuccess('Profile picture uploaded. Click "Save Changes" to update.');
                              };
                              reader.onerror = () => setError('Failed to read the image file. Please try again.');
                              reader.readAsDataURL(file);
                            }
                          }}
                          className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary-color file:text-white hover:file:bg-primary-dark"
                        />
                        <p className="text-xs text-gray-500 mt-1">Max file size: 2MB. Supported formats: JPG, PNG, GIF</p>
                      </div>
                    </div>
                    
                    {/* Store Location Section */}
                    {user.role === 'merchant' && (
                      <div className="mb-4">
                        <label className="block text-sm font-medium mb-1">Store Location (Google Map)</label>
                        <div className="mb-2">
                          {formData.locationLat && formData.locationLng ? (
                            <div className="mb-2">
                              <div className="text-xs text-gray-600 mb-1">Current Location: <span className="font-mono">{formData.locationLat.toFixed(6)}, {formData.locationLng.toFixed(6)}</span></div>
                              <button type="button" className="text-red-500 hover:text-red-700 text-xs mb-2" onClick={() => setFormData(prev => ({ ...prev, locationLat: '', locationLng: '' }))}>
                                Remove Location
                              </button>
                            </div>
                          ) : null}
                          <div id="store-map" style={{ width: '100%', height: '250px', borderRadius: '8px', border: '1px solid #e5e7eb', marginBottom: '8px' }}></div>
                          <button
                            type="button"
                            className="btn btn-primary px-3 py-1 mt-2"
                            onClick={() => {
                              // Try to get current location
                              if (navigator.geolocation) {
                                navigator.geolocation.getCurrentPosition(pos => {
                                  setFormData(prev => ({ ...prev, locationLat: pos.coords.latitude, locationLng: pos.coords.longitude }));
                                  if (window.setMapMarker) window.setMapMarker(pos.coords.latitude, pos.coords.longitude);
                                });
                              }
                            }}
                          >Use My Current Location</button>
                        </div>
                        <p className="text-xs text-gray-500 mt-1">Drag the marker or search to set your store's location. Only latitude/longitude will be saved.</p>
                      </div>
                    )}
                    
                    <button type="submit" className="btn btn-primary">
                      Save Changes
                    </button>
                  </form>
                </div>
              }
              
              {/* Security */}
              {activeTab === 'security' &&
              <div>
                  <h1 className="text-2xl font-bold mb-6">Security</h1>
                  
                  <form onSubmit={handlePasswordSubmit}>
                    <div className="mb-4">
                      <label className="block text-sm font-medium mb-1">Current Password</label>
                      <input
                      type="password"
                      name="currentPassword"
                      value={formData.currentPassword}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                      required />
                    </div>
                    
                    <div className="mb-4">
                      <label className="block text-sm font-medium mb-1">New Password</label>
                      <input
                      type="password"
                      name="newPassword"
                      value={formData.newPassword}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                      required />
                    </div>
                    
                    <div className="mb-4">
                      <label className="block text-sm font-medium mb-1">Confirm New Password</label>
                      <input
                      type="password"
                      name="confirmPassword"
                      value={formData.confirmPassword}
                      onChange={handleInputChange}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color"
                      required />
                    </div>
                    
                    <button type="submit" className="btn btn-primary">
                      Update Password
                    </button>
                  </form>
                </div>
              }
              
              {/* Notifications */}
              {activeTab === 'notifications' &&
              <div>
                  <h1 className="text-2xl font-bold mb-6">Notification Preferences</h1>
                  
                  <form onSubmit={handleProfileSubmit}>
                    <div className="space-y-4">
                      <div className="flex items-start">
                        <div className="flex items-center h-5">
                          <input
                          id="email"
                          name="email"
                          type="checkbox"
                          checked={formData.notifications.email}
                          onChange={handleNotificationChange}
                          className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" />
                        </div>
                        <div className="ml-3 text-sm">
                          <label htmlFor="email" className="font-medium text-gray-700">Email Notifications</label>
                          <p className="text-gray-500">Receive notifications via email</p>
                        </div>
                      </div>
                      
                      <div className="flex items-start">
                        <div className="flex items-center h-5">
                          <input
                          id="expiringDeals"
                          name="expiringDeals"
                          type="checkbox"
                          checked={formData.notifications.expiringDeals}
                          onChange={handleNotificationChange}
                          className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" />
                        </div>
                        <div className="ml-3 text-sm">
                          <label htmlFor="expiringDeals" className="font-medium text-gray-700">Expiring Deals</label>
                          <p className="text-gray-500">Get notified when your saved deals are about to expire</p>
                        </div>
                      </div>
                      
                      <div className="flex items-start">
                        <div className="flex items-center h-5">
                          <input
                          id="favoriteStores"
                          name="favoriteStores"
                          type="checkbox"
                          checked={formData.notifications.favoriteStores}
                          onChange={handleNotificationChange}
                          className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" />
                        </div>
                        <div className="ml-3 text-sm">
                          <label htmlFor="favoriteStores" className="font-medium text-gray-700">Favorite Stores</label>
                          <p className="text-gray-500">Get notified about new deals from your favorite stores</p>
                        </div>
                      </div>
                      
                      <div className="flex items-start">
                        <div className="flex items-center h-5">
                          <input
                          id="recommendations"
                          name="recommendations"
                          type="checkbox"
                          checked={formData.notifications.recommendations}
                          onChange={handleNotificationChange}
                          className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" />
                        </div>
                        <div className="ml-3 text-sm">
                          <label htmlFor="recommendations" className="font-medium text-gray-700">Personalized Recommendations</label>
                          <p className="text-gray-500">Get recommendations based on your preferences</p>
                        </div>
                      </div>
                    </div>
                    
                    <div className="mt-6">
                      <button type="submit" className="btn btn-primary">
                        Save Preferences
                      </button>
                    </div>
                  </form>
                </div>
              }
              
              {/* Favorites */}
              {activeTab === 'favorites' &&
              <div>
                  <h1 className="text-2xl font-bold mb-6">My Favorite Deals</h1>
                  
                  {savedPromotions.length === 0 ?
                <div className="text-center py-10">
                      <i className="far fa-heart text-5xl text-gray-300 mb-4"></i>
                      <p className="text-gray-500 mb-4">You haven't saved any deals yet</p>
                      <button
                    onClick={() => navigate('/categories/all')}
                    className="btn btn-primary">
                        Browse Deals
                      </button>
                    </div> :

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {savedPromotions.map((promotion) =>
                  <div key={promotion.id} className="bg-gray-50 rounded-lg p-4 relative">
                          <button
                      onClick={() => handleFavoriteToggle(promotion.id)}
                      className="absolute top-2 right-2 text-red-500 hover:text-red-700"
                      aria-label="Remove from favorites">
                            <i className="fas fa-times-circle"></i>
                          </button>
                          
                          <div className="flex">
                            <div className="flex-shrink-0 w-16 h-16 bg-gray-200 rounded overflow-hidden mr-4">
                              {promotion.image &&
                        <img
                          src={promotion.image}
                          alt={promotion.title}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "https://via.placeholder.com/300?text=No+Image";
                          }} />
                        }
                            </div>
                            
                            <div>
                              <h3 className="font-semibold">{promotion.title}</h3>
                              <p className="text-sm text-gray-500 mb-1">{promotion.merchant}</p>
                              <div className="flex items-center">
                                <code className="promo-code text-sm">{promotion.code}</code>
                                <span className="ml-2 text-sm bg-discount-red text-white px-2 py-0.5 rounded">
                                  {promotion.discount}
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                  )}
                    </div>
                }
                </div>
              }
              
              {/* Following */}
              {activeTab === 'following' &&
              <div>
                  <h1 className="text-2xl font-bold mb-6">Stores You Follow</h1>
                  
                  {followedMerchants.length === 0 ?
                <div className="text-center py-10">
                      <i className="fas fa-store text-5xl text-gray-300 mb-4"></i>
                      <p className="text-gray-500 mb-4">You're not following any stores yet</p>
                      <button
                    onClick={() => navigate('/merchants')}
                    className="btn btn-primary">
                        Discover Stores
                      </button>
                    </div> :

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {followedMerchants.map((merchant) =>
                  <div key={merchant.id} className="bg-white border rounded-lg overflow-hidden shadow-sm">
                          <div className="h-24 bg-gray-100 relative">
                            {merchant.logo &&
                      <img
                        src={merchant.logo}
                        alt={merchant.name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          e.target.onerror = null;
                          e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(merchant.name)}&background=random&size=300`;
                        }} />
                      }
                            <button
                        onClick={() => handleUnfollowMerchant(merchant.id)}
                        className="absolute top-2 right-2 bg-white rounded-full p-1 shadow-sm text-gray-500 hover:text-red-500"
                        aria-label="Unfollow">
                              <i className="fas fa-times"></i>
                            </button>
                          </div>
                          
                          <div className="p-4">
                            <h3 className="font-semibold">{merchant.name}</h3>
                            <p className="text-sm text-gray-500 mb-2">
                              <i className={`fas fa-${merchant.category === 'fashion' ? 'tshirt' : merchant.category === 'electronics' ? 'laptop' : 'home'} mr-1`}></i>
                              {typeof merchant.category === 'string' && merchant.category.length > 0
    ? merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1)
    : 'Other'}
                            </p>
                            <div className="flex justify-between items-center">
                              <span className="text-sm font-medium text-primary-color">
                                {merchant.activeDeals} active deals
                              </span>
                              <button
                          onClick={() => navigate(`/merchants/${merchant.id}`)}
                          className="text-sm text-gray-600 hover:text-primary-color">
                                View <i className="fas fa-chevron-right text-xs ml-1"></i>
                              </button>
                            </div>
                          </div>
                        </div>
                  )}
                    </div>
                }
                </div>
              }
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}