function PrivacyPolicyPage() {
  return (
    <div className="page-container">
      <div className="container py-8">
        <h1 className="text-3xl font-bold mb-4">Privacy Policy</h1>
        <p className="mb-4">Your privacy is important to us. This Privacy Policy explains how DealFinder collects, uses, and protects your information when you use our website and services.</p>
        <h2 className="text-xl font-semibold mt-6 mb-2">Information We Collect</h2>
        <ul className="mb-4 list-disc ml-6">
          <li>Personal information you provide (such as name, email, profile image)</li>
          <li>Usage data and cookies to improve your experience</li>
        </ul>
        <h2 className="text-xl font-semibold mt-6 mb-2">How We Use Your Information</h2>
        <ul className="mb-4 list-disc ml-6">
          <li>To provide and improve our services</li>
          <li>To communicate with you about updates and offers</li>
          <li>To ensure security and prevent fraud</li>
        </ul>
        <h2 className="text-xl font-semibold mt-6 mb-2">Your Choices</h2>
        <p className="mb-4">You can update your information or request deletion at any time by contacting us. We do not sell your personal data to third parties.</p>
        <p>For more details, please contact <a href="mailto:support@dealfinder.com" className="text-primary-color hover:underline">support@dealfinder.com</a>.</p>
      </div>
    </div>
  );
}

window.PrivacyPolicyPage = PrivacyPolicyPage;
