function UserProfile() {
  // const { useState } = React; // Not needed for this minimal version unless testing state
  // const [test, setTest] = React.useState("Test Value from State"); // Example if testing React hooks

  return React.createElement('div', { style: { padding: '20px', border: '2px solid green', margin: '10px' } },
    React.createElement('h1', { style: { color: 'green' } }, 'UserProfile Minimal Test - Does this load?'),
    React.createElement('p', null, 'If you see this message and the green bordered box, the basic UserProfile component is loading and rendering correctly using React.createElement (no JSX).'),
    React.createElement('p', null, 'Please check your browser console for any syntax errors or React Error #130.')
    // React.createElement('p', null, test) // Example if testing React hooks
  );
}
window.UserProfile = UserProfile; // Ensure it's globally available for the router
