// PromotionManagement.js
function PromotionManagement() {
  const { useState, useEffect } = React;
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingPromotion, setEditingPromotion] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [merchants, setMerchants] = useState([]); // For merchant dropdown

  const fetchPromotionsAndMerchants = async () => {
    try {
      setLoading(true);
      const [promoData, merchantData] = await Promise.all([
        window.API.Admin.getPromotions(),
        window.API.Admin.getMerchants() // Fetch merchants for the dropdown
      ]);
      setPromotions(promoData);
      setMerchants(merchantData);
    } catch (e) {
      console.error("Failed to fetch promotions or merchants:", e);
      setError('Failed to load data. ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPromotionsAndMerchants();
  }, []);

  const handleEdit = (promotion) => {
    setEditingPromotion(promotion);
    setShowForm(true);
  };

  const handleDelete = async (promotionId) => {
    if (confirm('Are you sure you want to delete this promotion?')) {
      try {
        await window.API.Admin.deletePromotion(promotionId);
        fetchPromotionsAndMerchants(); // Refresh list
      } catch (e) {
        console.error("Failed to delete promotion:", e);
        alert('Failed to delete promotion: ' + e.message);
      }
    }
  };

  const handleSave = async (promotionData) => {
    try {
      // Ensure merchant is merchantId
      if (promotionData.merchant && typeof promotionData.merchant === 'object') {
        promotionData.merchantId = promotionData.merchant._id;
        delete promotionData.merchant;
      } else {
        promotionData.merchantId = promotionData.merchant; // Assuming it's already an ID
      }


      if (editingPromotion && editingPromotion._id) {
        await window.API.Admin.updatePromotion(editingPromotion._id, promotionData);
      } else {
        await window.API.Admin.createPromotion(promotionData);
      }
      setShowForm(false);
      setEditingPromotion(null);
      fetchPromotionsAndMerchants(); // Refresh list
    } catch (e) {
      console.error("Failed to save promotion:", e);
      alert('Failed to save promotion: ' + e.message);
    }
  };

  const openNewPromotionForm = () => {
    setEditingPromotion(null);
    setShowForm(true);
  };

  if (loading) return <div className="text-center py-5"><i className="fas fa-spinner fa-spin text-2xl"></i> Loading promotions...</div>;
  if (error) return <div className="text-red-500 bg-red-100 p-3 rounded-md">Error: {error}</div>;

  return (
    <div className="p-4 bg-white shadow rounded-lg">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-semibold text-gray-800">Promotion Management</h2>
        <button onClick={openNewPromotionForm} className="btn btn-primary flex items-center">
          <i className="fas fa-plus mr-2"></i> Add Promotion
        </button>
      </div>

      {showForm && (
        <PromotionForm
          promotion={editingPromotion}
          merchants={merchants}
          onSave={handleSave}
          onCancel={() => { setShowForm(false); setEditingPromotion(null); }}
        />
      )}

      <div className="overflow-x-auto">
        <table className="min-w-full bg-white">
          <thead className="bg-gray-100">
            <tr>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Title</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Merchant</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Discount</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Category</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Status</th>
              <th className="text-center py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="text-gray-700">
            {promotions.map(promo => (
              <tr key={promo._id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="py-3 px-4">{promo.title}</td>
                <td className="py-3 px-4">{promo.merchant ? promo.merchant.name : 'N/A'}</td>
                <td className="py-3 px-4">{promo.discount}</td>
                <td className="py-3 px-4">{promo.category}</td>
                <td className="py-3 px-4">
                  <span className={`px-2 py-1 text-xs font-semibold rounded-full ${promo.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {promo.status}
                  </span>
                </td>
                <td className="py-3 px-4 text-center">
                  <button onClick={() => handleEdit(promo)} className="text-blue-500 hover:text-blue-700 mr-2">
                    <i className="fas fa-edit"></i>
                  </button>
                  <button onClick={() => handleDelete(promo._id)} className="text-red-500 hover:text-red-700">
                    <i className="fas fa-trash"></i>
                  </button>
                </td>
              </tr>
            ))}
            {promotions.length === 0 && (
              <tr><td colSpan="6" className="text-center py-4">No promotions found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// PromotionForm component
function PromotionForm({ promotion, merchants, onSave, onCancel }) {
  const { useState, useEffect } = React;
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    discount: '',
    code: '',
    category: '',
    merchant: '', // Should be merchant ID
    startDate: '',
    endDate: '',
    image: '',
    url: '',
    featured: false
  });

  useEffect(() => {
    if (promotion) {
      setFormData({
        title: promotion.title || '',
        description: promotion.description || '',
        discount: promotion.discount || '',
        code: promotion.code || '',
        category: promotion.category || '',
        merchant: promotion.merchant ? (typeof promotion.merchant === 'object' ? promotion.merchant._id : promotion.merchant) : '',
        startDate: promotion.startDate ? new Date(promotion.startDate).toISOString().split('T')[0] : '',
        endDate: promotion.endDate ? new Date(promotion.endDate).toISOString().split('T')[0] : '',
        image: promotion.image || '',
        url: promotion.url || '',
        featured: promotion.featured || false
      });
    } else {
      setFormData({ title: '', description: '', discount: '', code: '', category: '', merchant: '', startDate: '', endDate: '', image: '', url: '', featured: false });
    }
  }, [promotion]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({ ...prev, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    // Construct data to save, ensuring merchant is just the ID
    const dataToSave = {
        ...formData,
        merchantId: formData.merchant // Rename merchant to merchantId for backend
    };
    delete dataToSave.merchant; // remove the old merchant field
    onSave(dataToSave);
  };

  // Predefined categories - could also be fetched from API if dynamic
  const categories = ["Electronics", "Fashion", "Home & Garden", "Sports & Outdoors", "Health & Beauty", "Toys & Games", "Automotive", "Travel", "Food & Dining", "Services", "Other"];


  return (
    <form onSubmit={handleSubmit} className="p-4 mb-6 bg-gray-50 border border-gray-200 rounded-lg">
      <h3 className="text-xl font-semibold mb-4">{promotion ? 'Edit Promotion' : 'Add New Promotion'}</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="title" className="form-label">Title</label>
          <input type="text" name="title" id="title" value={formData.title} onChange={handleChange} required className="form-input" />
        </div>
        <div>
          <label htmlFor="merchant" className="form-label">Merchant</label>
          <select name="merchant" id="merchant" value={formData.merchant} onChange={handleChange} required className="form-input">
            <option value="">Select Merchant</option>
            {merchants.map(m => <option key={m._id} value={m._id}>{m.name}</option>)}
          </select>
        </div>
        <div className="md:col-span-2">
          <label htmlFor="description" className="form-label">Description</label>
          <textarea name="description" id="description" value={formData.description} onChange={handleChange} required rows="3" className="form-input"></textarea>
        </div>
        <div>
          <label htmlFor="discount" className="form-label">Discount (e.g., 50% off, $10 off)</label>
          <input type="text" name="discount" id="discount" value={formData.discount} onChange={handleChange} required className="form-input" />
        </div>
        <div>
          <label htmlFor="code" className="form-label">Promo Code (Optional)</label>
          <input type="text" name="code" id="code" value={formData.code} onChange={handleChange} className="form-input" />
        </div>
        <div>
          <label htmlFor="category" className="form-label">Category</label>
          <select name="category" id="category" value={formData.category} onChange={handleChange} required className="form-input">
            <option value="">Select Category</option>
            {categories.map(cat => <option key={cat} value={cat.toLowerCase().replace(/ & /g, '_').replace(/ /g, '_')}>{cat}</option>)}
          </select>
        </div>
        <div>
          <label htmlFor="startDate" className="form-label">Start Date</label>
          <input type="date" name="startDate" id="startDate" value={formData.startDate} onChange={handleChange} required className="form-input" />
        </div>
        <div>
          <label htmlFor="endDate" className="form-label">End Date</label>
          <input type="date" name="endDate" id="endDate" value={formData.endDate} onChange={handleChange} required className="form-input" />
        </div>
        <div>
          <label htmlFor="image" className="form-label">Image URL (Optional)</label>
          <input type="text" name="image" id="image" value={formData.image} onChange={handleChange} className="form-input" />
        </div>
        <div>
          <label htmlFor="url" className="form-label">Promotion URL (Link to deal)</label>
          <input type="text" name="url" id="url" value={formData.url} onChange={handleChange} className="form-input" />
        </div>
        <div className="md:col-span-2 flex items-center">
          <input type="checkbox" name="featured" id="featured" checked={formData.featured} onChange={handleChange} className="h-4 w-4 text-primary-color border-gray-300 rounded focus:ring-primary-color" />
          <label htmlFor="featured" className="ml-2 block text-sm text-gray-900">Featured Promotion</label>
        </div>
      </div>
      <div className="mt-6 flex justify-end space-x-3">
        <button type="button" onClick={onCancel} className="btn btn-secondary">Cancel</button>
        <button type="submit" className="btn btn-primary">Save Promotion</button>
      </div>
    </form>
  );
}

// Add to global CSS or components.css if not already defined:
// .form-label { display: block; text-sm; font-medium; text-gray-700; margin-bottom: 0.25rem; }
// .form-input { mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm }

window.PromotionManagement = PromotionManagement;
