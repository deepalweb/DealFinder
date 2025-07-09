const AdminPromotionsPage = () => {
  const { useState, useEffect, Fragment } = React;
  const { API } = window;
  const { Auth } = window;
  const { AdminModal, PromotionForm } = window;

  const [promotions, setPromotions] = useState([]);
  const [merchants, setMerchants] = useState([]); // For merchant dropdown in form
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [showModal, setShowModal] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [currentPromotionToEdit, setCurrentPromotionToEdit] = useState(null);
  const [modalKey, setModalKey] = useState(0);


  const promotionStatuses = [
    'pending_approval', 'approved', 'active', 'scheduled',
    'expired', 'rejected', 'admin_paused', 'draft'
  ];

  const fetchData = async () => {
    if (!Auth.isAdmin()) {
      setError("Access denied. You must be an admin to view this page.");
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      const [promoResponse, merchData] = await Promise.all([
        API.Promotions.adminGetAll(), // API returns { data: promotionsArray }
        API.Merchants.getAll()     // Fetches all merchants for the dropdown
      ]);
      setPromotions(promoResponse.data || []);
      setMerchants(merchData || []);
      setError(null);
    } catch (err) {
      console.error("Error fetching data for promotions page:", err);
      setError(err.message || "Failed to fetch data.");
      setPromotions([]);
      setMerchants([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleDeletePromotion = async (promotionId) => {
    if (!confirm('Are you sure you want to delete this promotion?')) {
      return;
    }
    try {
      await API.Promotions.delete(promotionId);
      fetchData();
      alert('Promotion deleted successfully.');
    } catch (err) {
      console.error("Error deleting promotion:", err);
      alert(`Failed to delete promotion: ${err.message}`);
    }
  };

  const handleStatusChange = async (promotionId, newStatus) => {
    if (!confirm(`Are you sure you want to change status to "${newStatus}" for this promotion?`)) {
      return;
    }
    try {
      await API.Promotions.update(promotionId, { status: newStatus });
      fetchData();
      alert('Promotion status updated successfully.');
    } catch (err) {
      console.error("Error updating promotion status:", err);
      alert(`Failed to update status: ${err.message}`);
    }
  };

  const handleOpenCreateModal = () => {
    setIsEditMode(false);
    setCurrentPromotionToEdit(null);
    setModalKey(prevKey => prevKey + 1);
    setShowModal(true);
  };

  const handleOpenEditModal = (promo) => {
    setIsEditMode(true);
    setCurrentPromotionToEdit(promo);
    setModalKey(prevKey => prevKey + 1);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setCurrentPromotionToEdit(null);
  };

  const handleFormSubmit = async (promotionData) => {
    try {
      if (isEditMode && currentPromotionToEdit) {
        await API.Promotions.update(currentPromotionToEdit._id, promotionData);
        alert('Promotion updated successfully.');
      } else {
        await API.Promotions.create(promotionData);
        alert('Promotion created successfully.');
      }
      fetchData();
      handleCloseModal();
    } catch (err) {
      console.error("Error saving promotion:", err);
      const errorMessage = err.response && err.response.data && err.response.data.message
                           ? err.response.data.message
                           : (err.message || (isEditMode ? "Failed to update promotion." : "Failed to create promotion."));
      alert(errorMessage);
    }
  };


  if (loading) {
    return React.createElement('div', null, 'Loading promotions data...');
  }

  if (error) {
    return React.createElement('div', { className: 'text-red-500' }, `Error: ${error}`);
  }

  return (
    React.createElement(Fragment, null,
      React.createElement('div', { className: 'flex justify-between items-center mb-6' },
        React.createElement('h1', { className: 'text-3xl font-bold' }, 'Promotion Management'),
        React.createElement('button', {
          onClick: handleOpenCreateModal,
          className: 'bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded'
        }, 'Create New Promotion')
      ),
      promotions.length === 0
        ? React.createElement('p', null, 'No promotions found.')
        : React.createElement('div', { className: 'overflow-x-auto shadow-md sm:rounded-lg' },
            React.createElement('table', { className: 'min-w-full divide-y divide-gray-200' },
              React.createElement('thead', { className: 'bg-gray-50' },
                React.createElement('tr', null,
                  React.createElement('th', { className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Title'),
                  React.createElement('th', { className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Merchant'),
                  React.createElement('th', { className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Status'),
                  React.createElement('th', { className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Dates (Start - End)'),
                  React.createElement('th', { className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Actions')
                )
              ),
              React.createElement('tbody', { className: 'bg-white divide-y divide-gray-200' },
                promotions.map(promo =>
                  React.createElement('tr', { key: promo._id },
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900' }, promo.title),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' }, promo.merchant ? promo.merchant.name : 'N/A'),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' },
                      promo.status ? promo.status.charAt(0).toUpperCase() + promo.status.slice(1).replace(/_/g, ' ') : 'N/A'
                    ),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' },
                      `${new Date(promo.startDate).toLocaleDateString()} - ${new Date(promo.endDate).toLocaleDateString()}`
                    ),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm font-medium' },
                      React.createElement('button', {
                        onClick: () => handleOpenEditModal(promo),
                        className: 'text-indigo-600 hover:text-indigo-900 mr-3'
                      }, 'Edit'),
                      React.createElement('button', {
                        onClick: () => handleDeletePromotion(promo._id),
                        className: 'text-red-600 hover:text-red-900 mr-3'
                      }, 'Delete'),
                      React.createElement('select', {
                          value: promo.status,
                          onChange: (e) => handleStatusChange(promo._id, e.target.value),
                          className: 'ml-2 p-1 border rounded text-xs bg-white shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500'
                        },
                        promotionStatuses.map(s =>
                          React.createElement('option', { key: s, value: s }, s.charAt(0).toUpperCase() + s.slice(1).replace(/_/g, ' '))
                        )
                      )
                    )
                  )
                )
              )
            )
          ),
        showModal && React.createElement(AdminModal, {
          isOpen: showModal,
          onClose: handleCloseModal,
          title: isEditMode ? 'Edit Promotion' : 'Create New Promotion'
        },
        React.createElement(PromotionForm, {
          key: modalKey,
          onSubmit: handleFormSubmit,
          initialPromotion: currentPromotionToEdit,
          isEditing: isEditMode,
          merchants: merchants /* Pass merchants list to form */
        }))
    )
  );
};

window.AdminPromotionsPage = AdminPromotionsPage;
