// A simple reusable modal component for admin forms
const AdminModal = ({ isOpen, onClose, title, children }) => {
  if (!isOpen) {
    return null;
  }

  const modalOverlayStyle = {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000, // Ensure it's on top
  };

  const modalContentStyle = {
    backgroundColor: '#fff',
    padding: '20px',
    borderRadius: '8px',
    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
    width: '90%',
    maxWidth: '500px', // Max width for the modal
    maxHeight: '90vh',
    overflowY: 'auto',
  };

  const modalHeaderStyle = {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '20px',
    borderBottom: '1px solid #eee',
    paddingBottom: '10px',
  };

  const modalTitleStyle = {
    fontSize: '1.5rem', // Equivalent to text-2xl
    fontWeight: 'bold',
  };

  const closeButtonStyle = {
    background: 'none',
    border: 'none',
    fontSize: '1.5rem',
    cursor: 'pointer',
    color: '#666',
  };

  return React.createElement('div', { style: modalOverlayStyle, onClick: onClose },
    React.createElement('div', { style: modalContentStyle, onClick: e => e.stopPropagation() }, // Prevents closing when clicking inside modal
      React.createElement('div', { style: modalHeaderStyle },
        React.createElement('h2', { style: modalTitleStyle }, title),
        React.createElement('button', { style: closeButtonStyle, onClick: onClose, 'aria-label': 'Close modal' },
          // HTML X character
          String.fromCharCode(215)
        )
      ),
      children // This is where the form or other modal content will go
    )
  );
};

window.AdminModal = AdminModal;
