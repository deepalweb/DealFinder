// Form component for creating and editing merchants
const MerchantForm = ({ onSubmit, initialMerchant = null, isEditing = false }) => {
  const { useState, useEffect } = React;

  const [name, setName] = useState('');
  const [profile, setProfile] = useState('');
  const [contactInfo, setContactInfo] = useState('');
  const [address, setAddress] = useState('');
  const [contactNumber, setContactNumber] = useState('');
  // Social media could be more complex, for now, simple inputs if needed or omit for brevity
  // const [facebook, setFacebook] = useState('');
  const [status, setStatus] = useState('active'); // Default status
  const [userIdToLink, setUserIdToLink] = useState(''); // For admin linking on create
  const [formErrors, setFormErrors] = useState({});

  const merchantStatuses = ['active', 'pending_approval', 'approved', 'rejected', 'suspended', 'needs_review'];

  useEffect(() => {
    if (isEditing && initialMerchant) {
      setName(initialMerchant.name || '');
      setProfile(initialMerchant.profile || '');
      setContactInfo(initialMerchant.contactInfo || '');
      setAddress(initialMerchant.address || '');
      setContactNumber(initialMerchant.contactNumber || '');
      setStatus(initialMerchant.status || 'active');
      setUserIdToLink(''); // Not applicable for editing in this form
    } else {
      // Reset for creation
      setName('');
      setProfile('');
      setContactInfo('');
      setAddress('');
      setContactNumber('');
      setStatus('active');
      setUserIdToLink('');
    }
  }, [initialMerchant, isEditing]);

  const validateForm = () => {
    const errors = {};
    if (!name.trim()) errors.name = 'Merchant name is required.';
    if (!contactInfo.trim()) errors.contactInfo = 'Contact info (e.g., email) is required.';
    // Basic email validation for contactInfo if it's an email
    // else if (contactInfo.includes('@') && !/\S+@\S+\.\S+/.test(contactInfo)) {
    //   errors.contactInfo = 'Contact info email is invalid.';
    // }
    if (!merchantStatuses.includes(status)) {
      errors.status = 'Invalid status selected.';
    }
    // Add more validations as needed (e.g., for userIdToLink if provided)
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validateForm()) {
      const merchantData = {
        name,
        profile,
        contactInfo,
        address,
        contactNumber,
        status
      };
      if (!isEditing && userIdToLink) {
        merchantData.userId = userIdToLink; // Only for creation by admin
      }
      onSubmit(merchantData);
    }
  };

  // Reusing styles from UserForm for consistency, or define them here
  const formGroupStyle = { marginBottom: '15px' };
  const labelStyle = { display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#333' };
  const inputStyle = {
    width: '100%',
    padding: '10px',
    border: '1px solid #ccc',
    borderRadius: '4px',
    boxSizing: 'border-box'
  };
  const textAreaStyle = { ...inputStyle, minHeight: '80px' };
  const errorStyle = { color: 'red', fontSize: '0.875em', marginTop: '5px' };
  const buttonStyle = {
    padding: '10px 20px', backgroundColor: '#007bff', color: 'white',
    border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '1em',
  };
  const disabledButtonStyle = { ...buttonStyle, backgroundColor: '#aaa', cursor: 'not-allowed' };

  return (
    React.createElement('form', { onSubmit: handleSubmit, noValidate: true },
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'merchantName', style: labelStyle }, 'Merchant Name:'),
        React.createElement('input', {
          type: 'text', id: 'merchantName', value: name,
          onChange: e => setName(e.target.value), style: inputStyle, required: true
        }),
        formErrors.name && React.createElement('p', { style: errorStyle }, formErrors.name)
      ),
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'merchantContact', style: labelStyle }, 'Contact Info (Email/Phone):'),
        React.createElement('input', {
          type: 'text', id: 'merchantContact', value: contactInfo,
          onChange: e => setContactInfo(e.target.value), style: inputStyle, required: true
        }),
        formErrors.contactInfo && React.createElement('p', { style: errorStyle }, formErrors.contactInfo)
      ),
       React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'merchantAddress', style: labelStyle }, 'Address:'),
        React.createElement('input', {
          type: 'text', id: 'merchantAddress', value: address,
          onChange: e => setAddress(e.target.value), style: inputStyle
        }),
        formErrors.address && React.createElement('p', { style: errorStyle }, formErrors.address)
      ),
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'merchantPhone', style: labelStyle }, 'Contact Number:'),
        React.createElement('input', {
          type: 'tel', id: 'merchantPhone', value: contactNumber,
          onChange: e => setContactNumber(e.target.value), style: inputStyle
        }),
        formErrors.contactNumber && React.createElement('p', { style: errorStyle }, formErrors.contactNumber)
      ),
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'merchantProfile', style: labelStyle }, 'Profile/Description:'),
        React.createElement('textarea', {
          id: 'merchantProfile', value: profile,
          onChange: e => setProfile(e.target.value), style: textAreaStyle
        }),
        formErrors.profile && React.createElement('p', { style: errorStyle }, formErrors.profile)
      ),
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'merchantStatus', style: labelStyle }, 'Status:'),
        React.createElement('select', {
          id: 'merchantStatus', value: status,
          onChange: e => setStatus(e.target.value), style: inputStyle
        },
          merchantStatuses.map(sVal =>
            React.createElement('option', { key: sVal, value: sVal }, sVal.charAt(0).toUpperCase() + sVal.slice(1).replace(/_/g, ' '))
          )
        ),
        formErrors.status && React.createElement('p', { style: errorStyle }, formErrors.status)
      ),
      !isEditing && React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'userIdToLink', style: labelStyle }, 'Link to User ID (Optional):'),
        React.createElement('input', {
          type: 'text', id: 'userIdToLink', value: userIdToLink,
          onChange: e => setUserIdToLink(e.target.value), style: inputStyle,
          placeholder: 'Enter existing User ID to make them a merchant'
        }),
        formErrors.userIdToLink && React.createElement('p', { style: errorStyle }, formErrors.userIdToLink)
      ),
      React.createElement('button', { type: 'submit', style: Object.keys(formErrors).length > 0 ? disabledButtonStyle : buttonStyle, disabled: Object.keys(formErrors).length > 0 },
        isEditing ? 'Save Changes' : 'Create Merchant'
      )
    )
  );
};

window.MerchantForm = MerchantForm;
