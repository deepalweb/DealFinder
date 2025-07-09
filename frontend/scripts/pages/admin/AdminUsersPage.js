const AdminUsersPage = () => {
  const { useState, useEffect, Fragment } = React;
  const { API } = window;
  const { Auth } = window;
  const { AdminModal, UserForm } = window; // Get components from window scope

  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [showModal, setShowModal] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [currentUserToEdit, setCurrentUserToEdit] = useState(null);
  const [modalKey, setModalKey] = useState(0); // Used to force re-mount of UserForm

  const fetchUsers = async () => {
    if (!Auth.isAdmin()) {
      setError("Access denied. You must be an admin to view this page.");
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      const fetchedUsers = await API.Users.getAll();
      setUsers(fetchedUsers);
      setError(null);
    } catch (err) {
      console.error("Error fetching users:", err);
      setError(err.message || "Failed to fetch users. Make sure you are logged in as an admin.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleDeleteUser = async (userId) => {
    if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
      return;
    }
    try {
      await API.Users.delete(userId);
      fetchUsers();
      alert('User deleted successfully.');
    } catch (err) {
      console.error("Error deleting user:", err);
      alert(`Failed to delete user: ${err.message}`);
    }
  };

  const handleOpenCreateModal = () => {
    setIsEditMode(false);
    setCurrentUserToEdit(null);
    setModalKey(prevKey => prevKey + 1); // Force re-mount of UserForm for fresh state
    setShowModal(true);
  };

  const handleOpenEditModal = (user) => {
    setIsEditMode(true);
    setCurrentUserToEdit(user);
    setModalKey(prevKey => prevKey + 1); // Force re-mount with initial data
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setCurrentUserToEdit(null); // Clear user data on close
  };

  const handleFormSubmit = async (userData) => {
    try {
      if (isEditMode && currentUserToEdit) {
        // API.Users.adminUpdate was added for this purpose
        await API.Users.adminUpdate(currentUserToEdit._id, userData);
        alert('User updated successfully.');
      } else {
        // API.Users.register can be used by admin to create user with role
        await API.Users.register(userData);
        alert('User created successfully.');
      }
      fetchUsers(); // Refresh user list
      handleCloseModal();
    } catch (err) {
      console.error("Error saving user:", err);
      // It's good to show specific backend error messages if available
      const errorMessage = err.response && err.response.data && err.response.data.message
                           ? err.response.data.message
                           : (err.message || (isEditMode ? "Failed to update user." : "Failed to create user."));
      alert(errorMessage);
      // Do not close modal on error, so user can correct
    }
  };

  if (loading) {
    return React.createElement('div', null, 'Loading users...');
  }

  if (error) {
    return React.createElement('div', { className: 'text-red-500' }, `Error: ${error}`);
  }

  return (
    React.createElement(Fragment, null,
      React.createElement('div', { className: 'flex justify-between items-center mb-6' },
        React.createElement('h1', { className: 'text-3xl font-bold' }, 'User Management'),
        React.createElement('button', {
          onClick: handleOpenCreateModal,
          className: 'bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded'
        }, 'Create New User')
      ),
      users.length === 0
        ? React.createElement('p', null, 'No users found.')
        : React.createElement('div', { className: 'overflow-x-auto shadow-md sm:rounded-lg' },
            React.createElement('table', { className: 'min-w-full divide-y divide-gray-200' },
              React.createElement('thead', { className: 'bg-gray-50' },
                React.createElement('tr', null,
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Name'),
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Email'),
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Role'),
                  React.createElement('th', { scope: 'col', className: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider' }, 'Actions')
                )
              ),
              React.createElement('tbody', { className: 'bg-white divide-y divide-gray-200' },
                users.map(user =>
                  React.createElement('tr', { key: user._id },
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900' }, user.name),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' }, user.email),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500' }, user.role),
                    React.createElement('td', { className: 'px-6 py-4 whitespace-nowrap text-sm font-medium' },
                      React.createElement('button', {
                        onClick: () => handleOpenEditModal(user),
                        className: 'text-indigo-600 hover:text-indigo-900 mr-3'
                      }, 'Edit'),
                      React.createElement('button', {
                        onClick: () => handleDeleteUser(user._id),
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
          title: isEditMode ? 'Edit User' : 'Create New User'
        },
        // UserForm is re-mounted when modalKey changes
        React.createElement(UserForm, {
          key: modalKey,
          onSubmit: handleFormSubmit,
          initialUser: currentUserToEdit,
          isEditing: isEditMode
        })
      )
    )
  );
};

window.AdminUsersPage = AdminUsersPage;
