// Form component for creating and editing promotions
const PromotionForm = ({ onSubmit, initialPromotion = null, isEditing = false, merchants = [] }) => {
  const { useState, useEffect } = React;

  // Initial state structure
  const getInitialState = () => {
    if (isEditing && initialPromotion) {
      return {
        title: initialPromotion.title || '',
        description: initialPromotion.description || '',
        discount: initialPromotion.discount || '',
        code: initialPromotion.code || '',
        category: initialPromotion.category || '',
        merchantId: initialPromotion.merchant ? (typeof initialPromotion.merchant === 'object' ? initialPromotion.merchant._id : initialPromotion.merchant) : '',
        startDate: initialPromotion.startDate ? new Date(initialPromotion.startDate).toISOString().split('T')[0] : '',
        endDate: initialPromotion.endDate ? new Date(initialPromotion.endDate).toISOString().split('T')[0] : '',
        image: initialPromotion.image || '',
        url: initialPromotion.url || '',
        featured: initialPromotion.featured || false,
        originalPrice: initialPromotion.originalPrice !== undefined ? initialPromotion.originalPrice : '',
        discountedPrice: initialPromotion.discountedPrice !== undefined ? initialPromotion.discountedPrice : '',
        status: initialPromotion.status || 'pending_approval',
      };
    }
    return {
      title: '', description: '', discount: '', code: '', category: '',
      merchantId: merchants.length > 0 ? merchants[0]._id : '', // Default to first merchant if available
      startDate: new Date().toISOString().split('T')[0],
      endDate: new Date(new Date().setDate(new Date().getDate() + 7)).toISOString().split('T')[0], // Default end date 7 days from now
      image: '', url: '', featured: false, originalPrice: '', discountedPrice: '',
      status: 'pending_approval', // Default for new promotions by admin could be 'approved'
    };
  };

  const [formData, setFormData] = useState(getInitialState());
  const [formErrors, setFormErrors] = useState({});

  const promotionStatuses = ['pending_approval', 'approved', 'rejected', 'admin_paused', 'draft', 'active', 'scheduled', 'expired'];
  // Categories could be dynamic, but using a static list for now
  const promotionCategories = ["Electronics", "Fashion", "Home & Garden", "Health & Beauty", "Sports & Outdoors", "Travel", "Food & Dining", "Services", "Other"];


  useEffect(() => {
    setFormData(getInitialState());
  }, [initialPromotion, isEditing, merchants]); // Add merchants to dependencies

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const validateForm = () => {
    const errors = {};
    if (!formData.title.trim()) errors.title = 'Title is required.';
    if (!formData.description.trim()) errors.description = 'Description is required.';
    if (!formData.discount.trim()) errors.discount = 'Discount description is required (e.g., "20% OFF").';
    if (!formData.code.trim()) errors.code = 'Promotion code is required.';
    if (!formData.category.trim()) errors.category = 'Category is required.';
    if (!formData.merchantId) errors.merchantId = 'Merchant is required.';
    if (!formData.startDate) errors.startDate = 'Start date is required.';
    if (!formData.endDate) errors.endDate = 'End date is required.';
    if (formData.startDate && formData.endDate && new Date(formData.endDate) < new Date(formData.startDate)) {
      errors.endDate = 'End date cannot be before start date.';
    }
    if (formData.originalPrice && isNaN(parseFloat(formData.originalPrice))) errors.originalPrice = 'Original price must be a number.';
    if (formData.discountedPrice && isNaN(parseFloat(formData.discountedPrice))) errors.discountedPrice = 'Discounted price must be a number.';
    if (formData.originalPrice && formData.discountedPrice && parseFloat(formData.discountedPrice) >= parseFloat(formData.originalPrice)) {
      errors.discountedPrice = 'Discounted price must be less than original price.';
    }
    if (!promotionStatuses.includes(formData.status)) errors.status = 'Invalid status.';

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validateForm()) {
      // Prepare data for submission, converting prices to numbers
      const submissionData = {
        ...formData,
        originalPrice: formData.originalPrice ? parseFloat(formData.originalPrice) : undefined,
        discountedPrice: formData.discountedPrice ? parseFloat(formData.discountedPrice) : undefined,
        featured: Boolean(formData.featured),
      };
      onSubmit(submissionData);
    }
  };

  // Basic inline styles (can be moved to CSS or a style object)
  const formGroupStyle = { marginBottom: '1rem' };
  const labelStyle = { display: 'block', marginBottom: '0.25rem', fontWeight: '600', color: '#4A5568' }; // text-gray-700
  const inputStyle = {
    width: '100%', padding: '0.5rem', border: '1px solid #CBD5E0', borderRadius: '0.25rem',
    boxSizing: 'border-box', backgroundColor: 'white' // bg-gray-50 border-gray-300
  };
  const checkboxLabelStyle = { marginLeft: '0.5rem', fontWeight: 'normal', color: '#4A5568' };
  const errorStyle = { color: '#E53E3E', fontSize: '0.875rem', marginTop: '0.25rem' }; // text-red-600
  const buttonStyle = {
    padding: '0.75rem 1.5rem', backgroundColor: '#4C51BF', color: 'white', // bg-indigo-600
    border: 'none', borderRadius: '0.25rem', cursor: 'pointer', fontSize: '1rem', fontWeight: '600'
  };
  const disabledButtonStyle = { ...buttonStyle, backgroundColor: '#A0AEC0', cursor: 'not-allowed' }; // bg-gray-400

  return (
    React.createElement('form', { onSubmit: handleSubmit, noValidate: true, className: 'space-y-4' },
      // Title, Description, Discount, Code
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'title', style: labelStyle }, 'Title:'),
        React.createElement('input', { type: 'text', name: 'title', id: 'title', value: formData.title, onChange: handleChange, style: inputStyle }),
        formErrors.title && React.createElement('p', { style: errorStyle }, formErrors.title)
      ),
      // ... (other similar fields: description, discount, code) ...
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'description', style: labelStyle }, 'Description:'),
        React.createElement('textarea', { name: 'description', id: 'description', value: formData.description, onChange: handleChange, style: {...inputStyle, minHeight: '80px'} }),
        formErrors.description && React.createElement('p', { style: errorStyle }, formErrors.description)
      ),
      React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 gap-4' },
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'discount', style: labelStyle }, 'Discount (e.g., 20% OFF):'),
          React.createElement('input', { type: 'text', name: 'discount', id: 'discount', value: formData.discount, onChange: handleChange, style: inputStyle }),
          formErrors.discount && React.createElement('p', { style: errorStyle }, formErrors.discount)
        ),
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'code', style: labelStyle }, 'Promo Code:'),
          React.createElement('input', { type: 'text', name: 'code', id: 'code', value: formData.code, onChange: handleChange, style: inputStyle }),
          formErrors.code && React.createElement('p', { style: errorStyle }, formErrors.code)
        )
      ),
      // Category and Merchant
      React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 gap-4' },
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'category', style: labelStyle }, 'Category:'),
          React.createElement('select', { name: 'category', id: 'category', value: formData.category, onChange: handleChange, style: inputStyle },
            React.createElement('option', { value: '' }, 'Select Category'),
            promotionCategories.map(cat => React.createElement('option', { key: cat, value: cat }, cat))
          ),
          formErrors.category && React.createElement('p', { style: errorStyle }, formErrors.category)
        ),
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'merchantId', style: labelStyle }, 'Merchant:'),
          React.createElement('select', { name: 'merchantId', id: 'merchantId', value: formData.merchantId, onChange: handleChange, style: inputStyle, disabled: merchants.length === 0 },
            merchants.length === 0 ? React.createElement('option', { value: '' }, 'No merchants available') : React.createElement('option', { value: '' }, 'Select Merchant'),
            merchants.map(m => React.createElement('option', { key: m._id, value: m._id }, m.name))
          ),
          formErrors.merchantId && React.createElement('p', { style: errorStyle }, formErrors.merchantId)
        )
      ),
      // Start Date and End Date
      React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 gap-4' },
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'startDate', style: labelStyle }, 'Start Date:'),
          React.createElement('input', { type: 'date', name: 'startDate', id: 'startDate', value: formData.startDate, onChange: handleChange, style: inputStyle }),
          formErrors.startDate && React.createElement('p', { style: errorStyle }, formErrors.startDate)
        ),
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'endDate', style: labelStyle }, 'End Date:'),
          React.createElement('input', { type: 'date', name: 'endDate', id: 'endDate', value: formData.endDate, onChange: handleChange, style: inputStyle }),
          formErrors.endDate && React.createElement('p', { style: errorStyle }, formErrors.endDate)
        )
      ),
      // Image URL and Promotion URL
       React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 gap-4' },
        React.createElement('div', { style: formGroupStyle },
            React.createElement('label', { htmlFor: 'image', style: labelStyle }, 'Image URL (Optional):'),
            React.createElement('input', { type: 'url', name: 'image', id: 'image', value: formData.image, onChange: handleChange, style: inputStyle, placeholder: 'https://example.com/image.png' }),
            formErrors.image && React.createElement('p', { style: errorStyle }, formErrors.image)
        ),
        React.createElement('div', { style: formGroupStyle },
            React.createElement('label', { htmlFor: 'url', style: labelStyle }, 'Promotion URL (Optional):'),
            React.createElement('input', { type: 'url', name: 'url', id: 'url', value: formData.url, onChange: handleChange, style: inputStyle, placeholder: 'https://example.com/promotion-link' }),
            formErrors.url && React.createElement('p', { style: errorStyle }, formErrors.url)
        )
      ),
      // Original Price and Discounted Price
      React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 gap-4' },
        React.createElement('div', { style: formGroupStyle },
            React.createElement('label', { htmlFor: 'originalPrice', style: labelStyle }, 'Original Price (Optional):'),
            React.createElement('input', { type: 'number', name: 'originalPrice', id: 'originalPrice', value: formData.originalPrice, onChange: handleChange, style: inputStyle, placeholder: 'e.g., 100.00', step: "0.01" }),
            formErrors.originalPrice && React.createElement('p', { style: errorStyle }, formErrors.originalPrice)
        ),
        React.createElement('div', { style: formGroupStyle },
            React.createElement('label', { htmlFor: 'discountedPrice', style: labelStyle }, 'Discounted Price (Optional):'),
            React.createElement('input', { type: 'number', name: 'discountedPrice', id: 'discountedPrice', value: formData.discountedPrice, onChange: handleChange, style: inputStyle, placeholder: 'e.g., 80.00', step: "0.01" }),
            formErrors.discountedPrice && React.createElement('p', { style: errorStyle }, formErrors.discountedPrice)
        )
      ),
      // Featured (Checkbox) and Status
      React.createElement('div', { className: 'grid grid-cols-1 md:grid-cols-2 gap-4 items-center' },
        React.createElement('div', { style: { ...formGroupStyle, marginTop: '1.5rem'} }, // Align with select
          React.createElement('input', { type: 'checkbox', name: 'featured', id: 'featured', checked: formData.featured, onChange: handleChange, className: 'form-checkbox h-5 w-5 text-indigo-600' }),
          React.createElement('label', { htmlFor: 'featured', style: checkboxLabelStyle }, 'Featured Promotion')
        ),
        React.createElement('div', { style: formGroupStyle },
          React.createElement('label', { htmlFor: 'status', style: labelStyle }, 'Status:'),
          React.createElement('select', { name: 'status', id: 'status', value: formData.status, onChange: handleChange, style: inputStyle },
            promotionStatuses.map(sVal => React.createElement('option', { key: sVal, value: sVal }, sVal.charAt(0).toUpperCase() + sVal.slice(1).replace(/_/g, ' ')))
          ),
          formErrors.status && React.createElement('p', { style: errorStyle }, formErrors.status)
        )
      ),
      // Submit Button
      React.createElement('div', { style: { ...formGroupStyle, marginTop: '2rem', textAlign: 'right' } },
        React.createElement('button', { type: 'submit', style: Object.keys(formErrors).length > 0 ? disabledButtonStyle : buttonStyle, disabled: Object.keys(formErrors).length > 0 },
          isEditing ? 'Save Changes' : 'Create Promotion'
        )
      )
    )
  );
};

window.PromotionForm = PromotionForm;
