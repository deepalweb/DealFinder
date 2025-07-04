// UserManagement.js
function UserManagement() {
  const { useState, useEffect } = React;
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingUser, setEditingUser] = useState(null); // User object for editing, or null for new user
  const [showForm, setShowForm] = useState(false);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const data = await window.API.Admin.getUsers();
      setUsers(data);
    } catch (e) {
      console.error("Failed to fetch users:", e);
      setError('Failed to load users. ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleEdit = (user) => {
    setEditingUser(user);
    setShowForm(true);
  };

  const handleDelete = async (userId) => {
    if (confirm('Are you sure you want to delete this user?')) {
      try {
        await window.API.Admin.deleteUser(userId);
        fetchUsers(); // Refresh list
      } catch (e) {
        console.error("Failed to delete user:", e);
        alert('Failed to delete user: ' + e.message);
      }
    }
  };

  const handleSave = async (userData) => {
    try {
      if (editingUser && editingUser._id) {
        await window.API.Admin.updateUser(editingUser._id, userData);
      } else {
        await window.API.Admin.createUser(userData);
      }
      setShowForm(false);
      setEditingUser(null);
      fetchUsers(); // Refresh list
    } catch (e) {
      console.error("Failed to save user:", e);
      alert('Failed to save user: ' + e.message);
    }
  };

  const openNewUserForm = () => {
    setEditingUser(null); // Ensure it's a new user
    setShowForm(true);
  };


  if (loading) return <div className="text-center py-5"><i className="fas fa-spinner fa-spin text-2xl"></i> Loading users...</div>;
  if (error) return <div className="text-red-500 bg-red-100 p-3 rounded-md">Error: {error}</div>;

  return (
    <div className="p-4 bg-white shadow rounded-lg">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-2xl font-semibold text-gray-800">User Management</h2>
        <button onClick={openNewUserForm} className="btn btn-primary flex items-center">
          <i className="fas fa-plus mr-2"></i> Add User
        </button>
      </div>

      {showForm && (
        <UserForm user={editingUser} onSave={handleSave} onCancel={() => { setShowForm(false); setEditingUser(null); }} />
      )}

      <div className="overflow-x-auto">
        <table className="min-w-full bg-white">
          <thead className="bg-gray-100">
            <tr>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Name</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Email</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Role</th>
              <th className="text-left py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Merchant ID</th>
              <th className="text-center py-3 px-4 font-semibold text-sm text-gray-600 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="text-gray-700">
            {users.map(user => (
              <tr key={user._id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="py-3 px-4">{user.name}</td>
                <td className="py-3 px-4">{user.email}</td>
                <td className="py-3 px-4">{user.role}</td>
                <td className="py-3 px-4">{user.merchantId || 'N/A'}</td>
                <td className="py-3 px-4 text-center">
                  <button onClick={() => handleEdit(user)} className="text-blue-500 hover:text-blue-700 mr-2">
                    <i className="fas fa-edit"></i>
                  </button>
                  <button onClick={() => handleDelete(user._id)} className="text-red-500 hover:text-red-700">
                    <i className="fas fa-trash"></i>
                  </button>
                </td>
              </tr>
            ))}
            {users.length === 0 && (
              <tr><td colSpan="5" className="text-center py-4">No users found.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// UserForm component (could be in its own file)
function UserForm({ user, onSave, onCancel }) {
  const { useState, useEffect } = React;
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '', // Only for new users or password changes
    role: 'user',
    businessName: '', // For merchants
    profilePicture: ''
  });

  useEffect(() => {
    if (user) {
      setFormData({
        name: user.name || '',
        email: user.email || '',
        password: '', // Keep password field blank for edits unless changing
        role: user.role || 'user',
        businessName: user.businessName || '',
        profilePicture: user.profilePicture || ''
      });
    } else {
      // Reset for new user form
      setFormData({ name: '', email: '', password: '', role: 'user', businessName: '', profilePicture: '' });
    }
  }, [user]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const dataToSave = { ...formData };
    if (!formData.password) { // Don't send empty password for updates unless it's meant to be cleared (which backend should handle)
      delete dataToSave.password;
    }
    onSave(dataToSave);
  };

  return (
    <form onSubmit={handleSubmit} className="p-4 mb-6 bg-gray-50 border border-gray-200 rounded-lg">
      <h3 className="text-xl font-semibold mb-4">{user ? 'Edit User' : 'Add New User'}</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700">Name</label>
          <input type="text" name="name" id="name" value={formData.name} onChange={handleChange} required className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm" />
        </div>
        <div>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700">Email</label>
          <input type="email" name="email" id="email" value={formData.email} onChange={handleChange} required className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm" />
        </div>
        <div>
          <label htmlFor="password" className="block text-sm font-medium text-gray-700">Password {user ? '(Leave blank to keep current)' : ''}</label>
          <input type="password" name="password" id="password" value={formData.password} onChange={handleChange} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm" />
        </div>
        <div>
          <label htmlFor="role" className="block text-sm font-medium text-gray-700">Role</label>
          <select name="role" id="role" value={formData.role} onChange={handleChange} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm">
            <option value="user">User</option>
            <option value="merchant">Merchant</option>
            <option value="admin">Admin</option>
          </select>
        </div>
        {formData.role === 'merchant' && (
          <div>
            <label htmlFor="businessName" className="block text-sm font-medium text-gray-700">Business Name</label>
            <input type="text" name="businessName" id="businessName" value={formData.businessName} onChange={handleChange} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm" />
          </div>
        )}
        <div>
          <label htmlFor="profilePicture" className="block text-sm font-medium text-gray-700">Profile Picture URL</label>
          <input type="text" name="profilePicture" id="profilePicture" value={formData.profilePicture} onChange={handleChange} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-color focus:border-primary-color sm:text-sm" />
        </div>
      </div>
      <div className="mt-6 flex justify-end space-x-3">
        <button type="button" onClick={onCancel} className="btn btn-secondary">Cancel</button>
        <button type="submit" className="btn btn-primary">Save User</button>
      </div>
    </form>
  );
}


window.UserManagement = UserManagement;
