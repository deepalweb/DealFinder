const AdminMerchantsPage = () => {
  const { useState, useEffect, Fragment } = React;
  const { API } = window;
  const { Auth } = window;
  const { AdminModal, MerchantForm } = window; // Get components from window scope

  const [merchants, setMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [showModal, setShowModal] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [currentMerchantToEdit, setCurrentMerchantToEdit] = useState(null);
  const [modalKey, setModalKey] = useState(0); // Used to force re-mount of MerchantForm

  const fetchMerchants = async () => {
    if (!Auth.isAdmin()) {
      setError("Access denied. You must be an admin to view this page.");
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      const fetchedMerchants = await API.Merchants.getAll();
      setMerchants(fetchedMerchants);
      setError(null);
    } catch (err) {
      console.error("Error fetching merchants:", err);
      setError(err.message || "Failed to fetch merchants.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMerchants();
  }, []);

  const handleDeleteMerchant = async (merchantId) => {
    if (!confirm('Are you sure you want to delete this merchant? This may also affect associated users and promotions.')) {
      return;
    }
    try {
      await API.Merchants.delete(merchantId);
      fetchMerchants();
      alert('Merchant deleted successfully.');
    } catch (err) {
      console.error("Error deleting merchant:", err);
      alert(`Failed to delete merchant: ${err.message}`);
    }
  };

  const handleOpenCreateModal = () => {
    setIsEditMode(false);
    setCurrentMerchantToEdit(null);
    setModalKey(prevKey => prevKey + 1);
    setShowModal(true);
  };

  const handleOpenEditModal = (merchant) => {
    setIsEditMode(true);
    setCurrentMerchantToEdit(merchant);
    setModalKey(prevKey => prevKey + 1);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setCurrentMerchantToEdit(null);
  };

  const handleFormSubmit = async (merchantData) => {
    try {
      if (isEditMode && currentMerchantToEdit) {
        // API.Merchants.update is used, backend auth allows admin to update any
        await API.Merchants.update(currentMerchantToEdit._id, merchantData);
        alert('Merchant updated successfully.');
      } else {
        // API.Merchants.create is already admin-only from apiHelpers.js
        // However, the backend POST /api/merchants is admin protected.
        // Let's assume API.Merchants.create is defined or add it.
        // For now, will use a generic 'create' or ensure it exists in API.Merchants
        if (!API.Merchants.create) { // A quick check, ideally API.Merchants.create would exist
            // The backend route POST /api/merchants is admin only and handles creation.
            // Need to ensure apiHelpers has a `create` method for merchants.
            // Let's assume for now it's added or use a direct fetch if not.
            // For this example, I'll construct it if missing, or you'd add it to apiHelpers.
            console.warn("API.Merchants.create not found, using direct fetch as fallback for this example.");
            await fetchAPI('merchants', { method: 'POST', body: JSON.stringify(merchantData) });
        } else {
            await API.Merchants.create(merchantData);
        }
        alert('Merchant created successfully.');
      }
      fetchMerchants();
      handleCloseModal();
    } catch (err) {
      console.error("Error saving merchant:", err);
      const errorMessage = err.response && err.response.data && err.response.data.message
                           ? err.response.data.message
                           : (err.message || (isEditMode ? "Failed to update merchant." : "Failed to create merchant."));
      alert(errorMessage);
    }
  };

  if (loading) {
    return React.createElement('div', null, 'Loading merchants...');
  }

  if (error) {
    return React.createElement('div', { className: 'text-red-500' }, `Error: ${error}`);
  }

  return (
    React.createElement(Fragment, null,
      React.createElement('div', { className: 'flex justify-between items-center mb-6' },
        React.createElement('h1', { className: 'text-3xl font-bold' }, 'Merchant Management'),
        React.createElement('button', {
          onClick: handleOpenCreateModal,
          className: 'bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded'
        }, 'Create New Merchant')
      ),
      merchants.length === 0
        ? React.createElement('p', null, 'No merchants found.')
        : React.createElement('div', { className: 'overflow-x-auto shadow-md sm:rounded-lg' },
            React.createElement('table', { className: 'min-w-full divide-y divide-gray-200' },
              React.createElement('thead', { className: 'bg-gray-50' },
                React.createElement('tr', null,
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Name'),
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Contact Info'),
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Status'),
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Actions')
                )
              ),
              React.createElement('tbody', { className: 'bg-white divide-y divide-gray-200' },
                merchants.map(merchant =>
                  React.createElement('tr', { key: merchant._id },
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900' }, merchant.name),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' }, merchant.contactInfo),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' },
                      merchant.status ? merchant.status.charAt(0).toUpperCase() + merchant.status.slice(1).replace(/_/g, ' ') : 'N/A'
                    ),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm font-medium' },
                      React.createElement('button', {
                        onClick: () => handleOpenEditModal(merchant),
                        className: 'text-indigo-600 hover:text-indigo-900 mr-3'
                      }, 'Edit/Approve'),
                      React.createElement('button', {
                        onClick: () => handleDeleteMerchant(merchant._id),
                        className: 'text-red-600 hover:text-red-900'
                      }, 'Delete')
                    )
                  )
                )
              )
            )
          ),
        showModal && React.createElement(AdminModal, {
          isOpen: showModal,
          onClose: handleCloseModal,
          title: isEditMode ? 'Edit Merchant' : 'Create New Merchant'
        },
        React.createElement(MerchantForm, {
          key: modalKey,
          onSubmit: handleFormSubmit,
          initialMerchant: currentMerchantToEdit,
          isEditing: isEditMode
        })
      )
    )
  );
};

window.AdminMerchantsPage = AdminMerchantsPage;
