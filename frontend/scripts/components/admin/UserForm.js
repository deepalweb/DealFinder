// Form component for creating and editing users
const UserForm = ({ onSubmit, initialUser = null, isEditing = false }) => {
  const { useState, useEffect } = React;

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('user'); // Default role
  const [formErrors, setFormErrors] = useState({});

  useEffect(() => {
    if (isEditing && initialUser) {
      setName(initialUser.name || '');
      setEmail(initialUser.email || '');
      setRole(initialUser.role || 'user');
      setPassword(''); // Password should not be pre-filled for editing
    } else {
      // Reset form for creation mode or if no initialUser
      setName('');
      setEmail('');
      setPassword('');
      setRole('user');
    }
  }, [initialUser, isEditing]);

  const validateForm = () => {
    const errors = {};
    if (!name.trim()) errors.name = 'Name is required.';
    if (!email.trim()) {
      errors.email = 'Email is required.';
    } else if (!/\S+@\S+\.\S+/.test(email)) { // Basic email validation
      errors.email = 'Email is invalid.';
    }
    if (!isEditing && !password) { // Password required only for creation
      errors.password = 'Password is required.';
    } else if (!isEditing && password && password.length < 8) {
      errors.password = 'Password must be at least 8 characters long.';
    }
    if (!['user', 'merchant', 'admin'].includes(role)) {
      errors.role = 'Invalid role selected.';
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validateForm()) {
      const userData = { name, email, role };
      if (!isEditing && password) {
        userData.password = password;
      } else if (isEditing && password) {
        // Optionally allow password change during edit if password field is filled
        // For now, we assume password change is separate or not done via this form's 'password' field for edits
        // If password change is desired here, backend must handle it.
        // Let's stick to not sending password on edit unless explicitly intended for reset/change.
        // The main user PUT endpoint was modified *not* to take password.
        // So, if admin wants to change password, they'd use a different mechanism or we'd need a specific field.
        // For simplicity, this form won't send password on edit.
      }
      onSubmit(userData);
    }
  };

  // Basic inline styles for form elements
  const formGroupStyle = { marginBottom: '15px' };
  const labelStyle = { display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#333' };
  const inputStyle = {
    width: '100%',
    padding: '10px',
    border: '1px solid #ccc',
    borderRadius: '4px',
    boxSizing: 'border-box' // Ensures padding doesn't add to width
  };
  const errorStyle = { color: 'red', fontSize: '0.875em', marginTop: '5px' };
  const buttonStyle = {
    padding: '10px 20px',
    backgroundColor: '#007bff', // Bootstrap primary blue
    color: 'white',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '1em',
  };
   const disabledButtonStyle = { ...buttonStyle, backgroundColor: '#aaa', cursor: 'not-allowed' };


  return (
    React.createElement('form', { onSubmit: handleSubmit, noValidate: true },
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'userName', style: labelStyle }, 'Name:'),
        React.createElement('input', {
          type: 'text', id: 'userName', value: name,
          onChange: e => setName(e.target.value), style: inputStyle, required: true
        }),
        formErrors.name && React.createElement('p', { style: errorStyle }, formErrors.name)
      ),
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'userEmail', style: labelStyle }, 'Email:'),
        React.createElement('input', {
          type: 'email', id: 'userEmail', value: email,
          onChange: e => setEmail(e.target.value), style: inputStyle, required: true
        }),
        formErrors.email && React.createElement('p', { style: errorStyle }, formErrors.email)
      ),
      // Password field only for creation, or if specifically designed for reset on edit
      // For now, strictly for creation.
      !isEditing && React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'userPassword', style: labelStyle }, 'Password:'),
        React.createElement('input', {
          type: 'password', id: 'userPassword', value: password,
          onChange: e => setPassword(e.target.value), style: inputStyle, required: !isEditing
        }),
        formErrors.password && React.createElement('p', { style: errorStyle }, formErrors.password)
      ),
      isEditing && React.createElement('p', {style: {fontSize: '0.9em', color: '#666', marginBottom: '15px'}}, 'Password cannot be changed from this form. Use the "Change Password" feature if available.'),
      React.createElement('div', { style: formGroupStyle },
        React.createElement('label', { htmlFor: 'userRole', style: labelStyle }, 'Role:'),
        React.createElement('select', {
          id: 'userRole', value: role,
          onChange: e => setRole(e.target.value), style: inputStyle
        },
          React.createElement('option', { value: 'user' }, 'User'),
          React.createElement('option', { value: 'merchant' }, 'Merchant'),
          React.createElement('option', { value: 'admin' }, 'Admin')
        ),
        formErrors.role && React.createElement('p', { style: errorStyle }, formErrors.role)
      ),
      React.createElement('button', { type: 'submit', style: Object.keys(formErrors).length > 0 ? disabledButtonStyle : buttonStyle, disabled: Object.keys(formErrors).length > 0 },
        isEditing ? 'Save Changes' : 'Create User'
      )
    )
  );
};

window.UserForm = UserForm;
