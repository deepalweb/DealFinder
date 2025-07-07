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

  // Form state (simplified version)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    logo: '', // User's own logo/avatar
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
    // Merchant specific fields like businessName, profile, contactInfo, address, etc., are removed for this baseline
    // locationLat and locationLng are also removed
  });

  useEffect(() => {
    try {
      const userData = localStorage.getItem('dealFinderUser');
      if (!userData) {
        navigate('/login');
        return;
      }
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      setImageKey(Date.now()); // For image previews if any
      
      setFormData(prevData => ({
        ...prevData,
        name: parsedUser.name || '',
        email: parsedUser.email || '',
        profilePicture: parsedUser.profilePicture || '',
        logo: parsedUser.logo || '', // Assuming user model might have a personal logo/avatar field
        notifications: {
          ...(prevData.notifications), // Keep defaults
          ...(parsedUser.preferences?.notifications || {})
        }
      }));
      setLoading(false); 

      if (parsedUser && parsedUser._id) {
        window.API.Users.getFavorites(parsedUser._id).then(favorites => {
          favorites = favorites.map(p => ({ ...p, id: p.id || p._id }));
          setSavedPromotions(favorites);
        }).catch(err => console.error("Failed to load favorites:", err));
      }
      
      let following = [];
      try {
        following = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
        following = following.map(m => ({ ...m, id: m.id || m._id }));
      } catch (e) { /* ignore parsing error */ }
      setFollowedMerchants(following);

    } catch (err) {
      console.error("Error in UserProfile initialization:", err);
      setError("Failed to load profile. Please try again.");
      setLoading(false);
    }
  }, [navigate]); // Run once on mount

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleNotificationChange = (e) => {
    const { name, checked } = e.target;
    setFormData(prevData => ({
      ...prevData,
      notifications: {
        ...prevData.notifications,
        [name]: checked
      }
    }));
  };

  const handleProfileSubmit = async (e) => {
    e.preventDefault();
    setSuccess('');
    setError('');
    setLoading(true);
    
    try {
      if (!user || !user._id) {
        setError('User information is missing. Please try logging in again.');
        setLoading(false);
        return;
      }
      
      setImageKey(Date.now());
      
      if (formData.logo && formData.logo.startsWith('data:image') && formData.logo.length > 2 * 1024 * 1024 * 1.4) { // Approx check for base64
        setError('Logo image is too large. Maximum size is 2MB.');
        setLoading(false);
        return;
      }
      if (formData.profilePicture && formData.profilePicture.startsWith('data:image') && formData.profilePicture.length > 2 * 1024 * 1024 * 1.4) {
        setError('Profile picture is too large. Maximum size is 2MB.');
        setLoading(false);
        return;
      }
      
      const profileDataToUpdate = {
        name: formData.name,
        // email is not updated
        logo: formData.logo, 
        profilePicture: formData.profilePicture,
        preferences: { // Include notification preferences
            notifications: formData.notifications
        }
      };
      
      const updatedUser = await window.API.Users.updateProfile(user._id, profileDataToUpdate);
      
      const updatedUserDataForStorage = {
        ...user, // existing user data from state (includes role, token, etc.)
        ...updatedUser, // updates from backend (might include new name, email if changed, etc.)
        logo: profileDataToUpdate.logo, // ensure frontend change for logo is reflected
        profilePicture: profileDataToUpdate.profilePicture, // ensure frontend change for profile pic is reflected
        preferences: updatedUser.preferences || user.preferences // take updated preferences
      };
      localStorage.setItem('dealFinderUser', JSON.stringify(updatedUserDataForStorage));
      setUser(updatedUserDataForStorage); // Update user state
      
      setSuccess('Profile updated successfully!');
    } catch (err) {
      console.error('Error updating profile:', err);
      setError(err.message || 'Failed to update profile. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordSubmit = (e) => {
    e.preventDefault();
    // ... (password submit logic - assuming it's okay for now)
    setSuccess('Password update UI - backend not implemented in this snippet.');
  };

  const handleFavoriteToggle = async (promotionId) => {
    if (!user || !user._id) return;
    try {
      await window.API.Users.removeFavorite(user._id, promotionId);
      setSavedPromotions(prev => prev.filter(p => p.id !== promotionId));
    } catch (err) { console.error('Failed to remove favorite:', err); }
  };

  const handleUnfollowMerchant = (merchantId) => {
    setFollowedMerchants(prev => prev.filter(m => m.id !== merchantId));
    localStorage.setItem('dealFinderFollowing', JSON.stringify(followedMerchants.filter(m => m.id !== merchantId)));
  };

  function getSafeProfileImage(profilePictureUrl, name) {
    if (profilePictureUrl && typeof profilePictureUrl === 'string' && (profilePictureUrl.startsWith('data:image') || profilePictureUrl.startsWith('http'))) {
      return profilePictureUrl;
    }
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'U')}&background=random&size=100`;
  }
  
  // Simplified getSafeLogo - assuming logo is for user avatar here in simplified version
   function getSafeLogo(logoUrl, name) { 
    if (logoUrl && typeof logoUrl === 'string' && (logoUrl.startsWith('data:image') || logoUrl.startsWith('http'))) {
      return logoUrl;
    }
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'L')}&background=random&size=100`;
  }


  if (loading && !user) { // Only show full page loader if user data isn't loaded yet
    return (
      <div className="page-container flex justify-center items-center">
        <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
      </div>);
  }
  
  if (!user) { // Should be navigated away by useEffect, but as a fallback
      return React.createElement('div', null, 'Redirecting to login...');
  }

  // JSX starts here
  return (
    React.createElement("div", { className: "page-container" },
      React.createElement("div", { className: "container py-8" },
        React.createElement("div", { className: "grid grid-cols-1 md:grid-cols-4 gap-6" },
          React.createElement("div", { className: "md:col-span-1" }, // Sidebar
            React.createElement("div", { className: "bg-white rounded-lg shadow-md p-6" },
              React.createElement("div", { className: "flex flex-col items-center mb-6" },
                React.createElement("div", { className: "w-20 h-20 bg-primary-color rounded-full flex items-center justify-center text-white text-2xl font-bold mb-2 overflow-hidden" },
                  React.createElement("img", {
                    src: getSafeProfileImage(formData.profilePicture, user.name),
                    alt: "Profile",
                    className: "w-full h-full object-cover",
                    onError: (e) => { e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name || 'U')}&background=random&size=100`; }
                  })
                ),
                React.createElement("h2", { className: "text-xl font-bold" }, user.name),
                React.createElement("p", { className: "text-gray-500" }, user.email),
                user.role === 'merchant' && React.createElement("span", { className: "mt-1 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-xs" }, "Merchant Account")
              ),
              React.createElement("nav", null,
                React.createElement("button", { className: `w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'profile' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`, onClick: () => setActiveTab('profile') }, React.createElement("i", { className: "fas fa-user-circle mr-2" }), " Profile Settings"),
                React.createElement("button", { className: `w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'security' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`, onClick: () => setActiveTab('security') }, React.createElement("i", { className: "fas fa-lock mr-2" }), " Security"),
                React.createElement("button", { className: `w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'notifications' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`, onClick: () => setActiveTab('notifications') }, React.createElement("i", { className: "fas fa-bell mr-2" }), " Notifications"),
                React.createElement("button", { className: `w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'favorites' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`, onClick: () => setActiveTab('favorites') }, React.createElement("i", { className: "fas fa-heart mr-2" }), " My Favorites"),
                React.createElement("button", { className: `w-full text-left py-2 px-4 rounded-md mb-1 flex items-center ${activeTab === 'following' ? 'bg-primary-color text-white' : 'hover:bg-gray-100'}`, onClick: () => setActiveTab('following') }, React.createElement("i", { className: "fas fa-store mr-2" }), " Following"),
                user.role === 'merchant' && React.createElement("button", { className: "w-full text-left py-2 px-4 rounded-md mb-1 flex items-center hover:bg-gray-100", onClick: () => navigate('/merchant/dashboard') }, React.createElement("i", { className: "fas fa-chart-line mr-2" }), " Merchant Dashboard"),
                React.createElement("hr", { className: "my-4" }),
                React.createElement("button", { className: "w-full text-left py-2 px-4 rounded-md mb-1 flex items-center text-red-500 hover:bg-red-50", onClick: () => { localStorage.removeItem('dealFinderUser'); navigate('/login'); } }, React.createElement("i", { className: "fas fa-sign-out-alt mr-2" }), " Logout")
              )
            )
          ),
          React.createElement("div", { className: "md:col-span-3" }, // Main content
            React.createElement("div", { className: "bg-white rounded-lg shadow-md p-6" },
              success && React.createElement("div", { className: "bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4" }, success),
              error && React.createElement("div", { className: "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4" }, error),

              activeTab === 'profile' && React.createElement("div", null,
                React.createElement("h1", { className: "text-2xl font-bold mb-6" }, "Profile Settings"),
                React.createElement("form", { onSubmit: handleProfileSubmit },
                  React.createElement("div", { className: "mb-4" },
                    React.createElement("label", { className: "block text-sm font-medium mb-1", htmlFor: "name" }, "Full Name"),
                    React.createElement("input", { type: "text", name: "name", id: "name", value: formData.name, onChange: handleInputChange, className: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color", required: true })
                  ),
                  React.createElement("div", { className: "mb-4" },
                    React.createElement("label", { className: "block text-sm font-medium mb-1", htmlFor: "email" }, "Email Address"),
                    React.createElement("input", { type: "email", name: "email", id: "email", value: formData.email, onChange: handleInputChange, className: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color", required: true, disabled: true }),
                    React.createElement("p", { className: "text-sm text-gray-500 mt-1" }, "Email cannot be changed")
                  ),
                  // Simplified: No merchant-specific fields in this baseline form.
                  // Profile Picture Upload (kept as it's general)
                  React.createElement("div", {className: "mb-4"},
                    React.createElement("label", {className: "block text-sm font-medium mb-1"}, "Profile Picture"),
                    React.createElement("div", {className: "flex items-center space-x-4 mb-2"},
                      React.createElement("div", {className: "w-16 h-16 bg-gray-200 rounded-full overflow-hidden flex-shrink-0"},
                        React.createElement("img", {
                          key: `profile-${imageKey}`, // ensure key changes
                          src: getSafeProfileImage(formData.profilePicture, formData.name),
                          alt: "Profile Preview",
                          className: "w-full h-full object-cover"
                        })
                      ),
                      React.createElement("input", {
                        type: "file", accept: "image/jpeg,image/png,image/gif",
                        onChange: e => {
                          const file = e.target.files[0];
                          if (file) {
                            if (file.size > 2 * 1024 * 1024) { setError('Image file is too large. Maximum size is 2MB.'); e.target.value = ''; return; }
                            const reader = new FileReader();
                            reader.onloadend = () => { setFormData(prev => ({ ...prev, profilePicture: reader.result })); setSuccess('Profile picture selected. Click "Save Changes".'); };
                            reader.onerror = () => setError('Failed to read image file.');
                            reader.readAsDataURL(file);
                          }
                        },
                        className: "block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-primary-color file:text-white hover:file:bg-primary-dark"
                      })
                    ),
                     React.createElement("p", {className: "text-xs text-gray-500 mt-1"}, "Max file size: 2MB.")
                  ),
                  React.createElement("button", { type: "submit", className: "btn btn-primary" }, "Save Changes")
                )
              ),
              activeTab === 'security' && React.createElement("div", null, /* Security content */ React.createElement("h1", {className: "text-2xl font-bold mb-6"}, "Security")),
              activeTab === 'notifications' && React.createElement("div", null, /* Notifications content */ React.createElement("h1", {className: "text-2xl font-bold mb-6"}, "Notification Preferences")),
              activeTab === 'favorites' && React.createElement("div", null, /* Favorites content */ React.createElement("h1", {className: "text-2xl font-bold mb-6"}, "My Favorite Deals")),
              activeTab === 'following' && React.createElement("div", null, /* Following content */ React.createElement("h1", {className: "text-2xl font-bold mb-6"}, "Stores You Follow"))
            )
          )
        )
      )
    )
  );
}
window.UserProfile = UserProfile; // Expose component to global scope for router
