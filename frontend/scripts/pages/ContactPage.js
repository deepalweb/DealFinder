function ContactPage() {
  return (
    <div className="page-container bg-gray-50 min-h-screen">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-r from-blue-600 to-indigo-700 text-white">
        <div className="container mx-auto px-4 py-16 md:py-24">
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight mb-4 animate-fade-in">
            Get in Touch
          </h1>
          <p className="text-lg md:text-xl max-w-2xl leading-relaxed animate-fade-in delay-100">
            Have questions, feedback, or partnership inquiries? We're here to help!
          </p>
        </div>
      </div>

      {/* Contact Info Section (static, no icons) */}
      <div className="container mx-auto px-4 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Contact Info */}
          <div className="space-y-6">
            <h2 className="text-2xl font-bold text-gray-800">Contact Information</h2>
            <div className="flex items-start space-x-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-800">Email</h3>
                <a
                  href="mailto:support@dealfinder.com"
                  className="text-indigo-600 hover:underline"
                >
                  support@dealfinder.com
                </a>
              </div>
            </div>
            <div className="flex items-start space-x-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-800">Phone</h3>
                <a
                  href="tel:+1234567890"
                  className="text-indigo-600 hover:underline"
                >
                  +1 (234) 567-890
                </a>
              </div>
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-800 mb-2">Our Hours</h3>
              <p className="text-gray-600">Monday - Friday: 9 AM - 5 PM (EST)</p>
              <p className="text-gray-600">Saturday - Sunday: Closed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Call to Action */}
      <div className="bg-indigo-700 text-white py-12">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">Explore More with DealFinder</h2>
          <p className="text-lg max-w-xl mx-auto mb-6">
            Ready to start saving? Check out the latest deals and promotions now.
          </p>
          <a
            href="/deals"
            className="inline-block bg-white text-indigo-700 font-semibold px-6 py-3 rounded-lg hover:bg-gray-100 transition-colors duration-300"
          >
            Discover Deals
          </a>
        </div>
      </div>
    </div>
  );
}

// Animation styles
const styles = `
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }
  .animate-fade-in {
    animation: fadeIn 0.6s ease-out forwards;
  }
  .delay-100 {
    animation-delay: 100ms;
  }
`;

window.ContactPage = ContactPage;
