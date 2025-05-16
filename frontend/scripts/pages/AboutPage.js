function AboutPage() {
  return (
    <div className="page-container bg-gray-50 min-h-screen">
      {/* Hero Section */}
      <div className="relative bg-gradient-to-r from-blue-600 to-indigo-700 text-white">
        <div className="container mx-auto px-4 py-16 md:py-24">
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight mb-4 animate-fade-in">
            About DealFinder
          </h1>
          <p className="text-lg md:text-xl max-w-2xl leading-relaxed animate-fade-in delay-100">
            We're on a mission to make saving money effortless, exciting, and accessible for everyone.
          </p>
        </div>
      </div>

      {/* Mission & Values Section */}
      <div className="container mx-auto px-4 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <div>
            <h2 className="text-3xl font-bold text-gray-800 mb-4">Our Story</h2>
            <p className="text-gray-600 leading-relaxed mb-4">
              DealFinder was born from a simple idea: finding great deals shouldn't be a chore. Our team of deal hunters, tech enthusiasts, and customer advocates work tirelessly to curate the best offers from your favorite merchants.
            </p>
            <p className="text-gray-600 leading-relaxed">
              We believe in creating a seamless experience that connects shoppers with savings and helps merchants reach their audience. Every deal we share is a step toward making shopping smarter and more rewarding.
            </p>
          </div>
          <div className="relative">
            <img
              src="https://images.unsplash.com/photo-1516321318423-f06f85e504b3?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
              alt="Team collaboration"
              className="rounded-lg shadow-lg transform hover:scale-105 transition-transform duration-300"
            />
          </div>
        </div>
      </div>

      {/* Values Section */}
      <div className="bg-white py-12 md:py-16">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-gray-800 text-center mb-12">Our Core Values</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            {[
              {
                title: "Passion for Savings",
                description: "We hunt for the best deals so you can shop with confidence and save more."
              },
              {
                title: "User-First Approach",
                description: "Our platform is designed to make your deal-finding experience seamless and fun."
              },
              {
                title: "Community Driven",
                description: "We connect shoppers and merchants to create a thriving savings ecosystem."
              }
            ].map((value, index) => (
              <div
                key={index}
                className="p-6 bg-gray-50 rounded-lg shadow-sm hover:shadow-md transition-shadow duration-300 text-center"
              >
                <h3 className="text-xl font-semibold text-gray-800 mb-2">{value.title}</h3>
                <p className="text-gray-600">{value.description}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Call to Action */}
      <div className="bg-indigo-700 text-white py-12">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">Join the DealFinder Community</h2>
          <p className="text-lg max-w-xl mx-auto mb-6">
            Start exploring the best deals today and experience shopping like never before.
          </p>
          <a
            href="/deals"
            className="inline-block bg-white text-indigo-700 font-semibold px-6 py-3 rounded-lg hover:bg-gray-100 transition-colors duration-300"
          >
            Discover Deals Now
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

window.AboutPage = AboutPage;
