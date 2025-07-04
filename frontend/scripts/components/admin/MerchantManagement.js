// MerchantManagement.js
function MerchantManagement() {
  const { useState, useEffect } = React;
  const [merchants, setMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingMerchant, setEditingMerchant] = useState(null);
  const [showForm, setShowForm] = useState(false);

  const fetchMerchants = async () => {
    try {
      setLoading(true);
      const data = await window.API.Admin.getMerchants();
      setMerchants(data);
    } catch (e) {
      console.error("Failed to fetch merchants:", e);
      setError('Failed to load merchants. ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMerchants();
  }, []);

  const handleEdit = (merchant) => {
    setEditingMerchant(merchant);
    setShowForm(true);
  };

  const handleDelete = async (merchantId) => {
    if (confirm('Are you sure you want to delete this merchant? This will also delete their promotions.')) {
      try {
        await window.API.Admin.deleteMerchant(merchantId);
        fetchMerchants(); // Refresh list
      } catch (e) {
        console.error("Failed to delete merchant:", e);
        alert('Failed to delete merchant: ' + e.message);
      }
    }
  };

  const handleSave = async (merchantData) => {
    try {
      if (editingMerchant && editingMerchant._id) {
        await window.API.Admin.updateMerchant(editingMerchant._id, merchantData);
      } else {
        await window.API.Admin.createMerchant(merchantData);
      }
      setShowForm(false);
      setEditingMerchant(null);
      fetchMerchants(); // Refresh list
    } catch (e) {
      console.error("Failed to save merchant:", e);
      alert('Failed to save merchant: ' + e.message);
    }
  };

  const openNewMerchantForm = () => {
    setEditingMerchant(null);
    setShowForm(true);
  };

  if (loading) return <div className="text-center py-5"><i className="fas fa-spinner fa-spin text-2xl"></i> Loading merchants...</div>;
  if (error) return <div className="text-red-500 bg-red-100 p-3 rounded-md">Error: {error}</div>;

  return (
    <div className="p-4 bg-white shadow rounded-lg">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-semibold text-gray-800">Merchant Management</h2>
        <button onClick={openNewMerchantForm} className="btn btn-primary flex items-center">
          <i className="fas fa-plus mr-2"></i> Add Merchant
        </button>
      </div>

      {showForm && (
        <MerchantForm merchant={editingMerchant} onSave={handleSave} onCancel={() => { setShowForm(false); setEditingMerchant(null); }} />
      )}

      <div className="overflow-x-auto">
        <table className="min-w-full bg-white">
          <thead className="bg-gray-100">
            <tr>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Name</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Contact Info</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Promotions</th>
              <th className="text-center py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="text-gray-700">
            {merchants.map(merchant => (
              <tr key={merchant._id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="py-3 px-4">{merchant.name}</td>
                <td className="py-3 px-4">{merchant.contactInfo}</td>
                <td className="py-3 px-4">{merchant.promotions ? merchant.promotions.length : 0}</td>
                <td className="py-3 px-4 text-center">
                  <button onClick={() => handleEdit(merchant)} className="text-blue-500 hover:text-blue-700 mr-2">
                    <i className="fas fa-edit"></i>
                  </button>
                  <button onClick={() => handleDelete(merchant._id)} className="text-red-500 hover:text-red-700">
                    <i className="fas fa-trash"></i>
                  </button>
                </td>
              </tr>
            ))}
            {merchants.length === 0 && (
              <tr><td colSpan="4" className="text-center py-4">No merchants found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// MerchantForm component
function MerchantForm({ merchant, onSave, onCancel }) {
  const { useState, useEffect } = React;
  const [formData, setFormData] = useState({
    name: '',
    profile: '',
    contactInfo: '',
    logo: '',
    address: '',
    contactNumber: '',
    socialMedia: { facebook: '', instagram: '', twitter: '', tiktok: '' },
    userId: '' // Optional: To link to an existing user
  });

  useEffect(() => {
    if (merchant) {
      setFormData({
        name: merchant.name || '',
        profile: merchant.profile || '',
        contactInfo: merchant.contactInfo || '',
        logo: merchant.logo || '',
        address: merchant.address || '',
        contactNumber: merchant.contactNumber || '',
        socialMedia: merchant.socialMedia || { facebook: '', instagram: '', twitter: '', tiktok: '' },
        userId: '' // Typically not edited directly here, but shown for context or set on creation
      });
    } else {
      setFormData({ name: '', profile: '', contactInfo: '', logo: '', address: '', contactNumber: '', socialMedia: { facebook: '', instagram: '', twitter: '', tiktok: '' }, userId: '' });
    }
  }, [merchant]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name.startsWith("socialMedia.")) {
      const key = name.split(".")[1];
      setFormData(prev => ({ ...prev, socialMedia: { ...prev.socialMedia, [key]: value } }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="p-4 mb-6 bg-gray-50 border border-gray-200 rounded-lg">
      <h3 className="text-xl font-semibold mb-4">{merchant ? 'Edit Merchant' : 'Add New Merchant'}</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700">Name</label>
          <input type="text" name="name" id="name" value={formData.name} onChange={handleChange} required className="form-input" />
        </div>
        <div>
          <label htmlFor="contactInfo" className="block text-sm font-medium text-gray-700">Contact Info (Email/Phone)</label>
          <input type="text" name="contactInfo" id="contactInfo" value={formData.contactInfo} onChange={handleChange} className="form-input" />
        </div>
        <div>
          <label htmlFor="address" className="block text-sm font-medium text-gray-700">Address</label>
          <input type="text" name="address" id="address" value={formData.address} onChange={handleChange} className="form-input" />
        </div>
        <div>
          <label htmlFor="contactNumber" className="block text-sm font-medium text-gray-700">Contact Number</label>
          <input type="text" name="contactNumber" id="contactNumber" value={formData.contactNumber} onChange={handleChange} className="form-input" />
        </div>
        <div className="md:col-span-2">
          <label htmlFor="profile" className="block text-sm font-medium text-gray-700">Profile (Description)</label>
          <textarea name="profile" id="profile" value={formData.profile} onChange={handleChange} rows="3" className="form-input"></textarea>
        </div>
        <div>
          <label htmlFor="logo" className="block text-sm font-medium text-gray-700">Logo URL</label>
          <input type="text" name="logo" id="logo" value={formData.logo} onChange={handleChange} className="form-input" />
        </div>
        {/* Optional: Link to existing user - more complex UI might be needed to select user */}
        {!merchant && ( // Only show on create form
            <div>
                <label htmlFor="userId" className="block text-sm font-medium text-gray-700">Link to User ID (Optional)</label>
                <input type="text" name="userId" id="userId" value={formData.userId} onChange={handleChange} className="form-input" placeholder="Existing User ID"/>
            </div>
        )}
      </div>
      <fieldset className="mt-4 border p-4 rounded-md">
        <legend className="text-sm font-medium text-gray-700 px-1">Social Media (Optional)</legend>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-2">
            <div>
                <label htmlFor="socialMedia.facebook" className="block text-xs font-medium text-gray-600">Facebook URL</label>
                <input type="text" name="socialMedia.facebook" id="socialMedia.facebook" value={formData.socialMedia.facebook} onChange={handleChange} className="form-input-sm" />
            </div>
            <div>
                <label htmlFor="socialMedia.instagram" className="block text-xs font-medium text-gray-600">Instagram URL</label>
                <input type="text" name="socialMedia.instagram" id="socialMedia.instagram" value={formData.socialMedia.instagram} onChange={handleChange} className="form-input-sm" />
            </div>
            <div>
                <label htmlFor="socialMedia.twitter" className="block text-xs font-medium text-gray-600">Twitter URL</label>
                <input type="text" name="socialMedia.twitter" id="socialMedia.twitter" value={formData.socialMedia.twitter} onChange={handleChange} className="form-input-sm" />
            </div>
            <div>
                <label htmlFor="socialMedia.tiktok" className="block text-xs font-medium text-gray-600">TikTok URL</label>
                <input type="text" name="socialMedia.tiktok" id="socialMedia.tiktok" value={formData.socialMedia.tiktok} onChange={handleChange} className="form-input-sm" />
            </div>
        </div>
      </fieldset>
      <div className="mt-6 flex justify-end space-x-3">
        <button type="button" onClick={onCancel} className="btn btn-secondary">Cancel</button>
        <button type="submit" className="btn btn-primary">Save Merchant</button>
      </div>
    </form>
  );
}

// Helper class for form inputs
// Add to global CSS or components.css:
// .form-input { mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm }
// .form-input-sm { mt-1 block w-full px-2 py-1 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-xs }


window.MerchantManagement = MerchantManagement;
