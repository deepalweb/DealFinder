// Validation helper functions

// Validate URL format
function validateURL(url) {
  if (!url) return true; // Empty URLs are considered valid (optional field)
  
  // Check if URL starts with http:// or https://
  const pattern = /^(https?:\/\/)/i;
  return pattern.test(url);
}

// Validate email format
function validateEmail(email) {
  const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return pattern.test(email);
}

// Validate password strength
function validatePassword(password) {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
  const pattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
  return pattern.test(password);
}

// Optimize image for upload
async function optimizeImage(dataUrl, maxWidth = 800, quality = 0.8) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      let width = img.width;
      let height = img.height;
      
      // Scale down if width is greater than maxWidth
      if (width > maxWidth) {
        height = Math.floor(height * (maxWidth / width));
        width = maxWidth;
      }
      
      canvas.width = width;
      canvas.height = height;
      
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, width, height);
      
      // Convert to data URL with quality setting
      const optimizedDataUrl = canvas.toDataURL('image/jpeg', quality);
      resolve(optimizedDataUrl);
    };
    
    img.onerror = reject;
    img.src = dataUrl;
  });
}

// Format date for display
function formatDate(dateString) {
  if (!dateString) return '';
  
  const options = { year: 'numeric', month: 'short', day: 'numeric' };
  return new Date(dateString).toLocaleDateString('en-US', options);
}

// Export validation functions to window object for global access
window.validateURL = validateURL;
window.validateEmail = validateEmail;
window.validatePassword = validatePassword;
window.optimizeImage = optimizeImage;
window.formatDate = formatDate;