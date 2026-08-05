import '../models/service_offering.dart';
import '../theme/app_theme.dart';

const List<String> hostelFilters = ['All', 'PG', 'Hostel', 'Service Apt', 'Flat', 'For Men', 'For Women'];

const List<({String step, String title, String desc})> hostelHowItWorks = [
  (step: '1', title: 'Search & Filter', desc: 'Enter location, budget & preferences to find matching PGs instantly'),
  (step: '2', title: 'View & Compare', desc: 'See photos, amenities, reviews and compare multiple options'),
  (step: '3', title: 'Visit & Book', desc: 'Schedule a visit or book directly through app with instant confirmation'),
  (step: '4', title: 'Move In', desc: 'Digital check-in, pay rent online, raise complaints via GateHub360 app'),
];

const List<String> propertyModes = ['Buy', 'Rent', 'Sell', 'Commercial'];
const List<String> propertyTypes = ['All', 'Apartment', 'Villa', 'Plot', 'Commercial'];
const List<String> propertyBhks = ['All', '1 BHK', '2 BHK', '3 BHK', '4+ BHK'];

const List<({String n, String title, String desc})> whyProperty = [
  (n: '✓', title: 'Verified Listings', desc: 'Every property verified before listing. No fake ads.'),
  (n: '0', title: 'Zero Brokerage', desc: 'Connect directly with builders and owners.'),
  (n: '📱', title: 'Virtual Tours', desc: '360° virtual property tours from your phone.'),
  (n: '💬', title: 'Expert Advice', desc: 'Free consultation with property experts.'),
];

const List<ServiceOffering> serviceOfferings = [
  ServiceOffering(slug: 'plumbing', emoji: '🔧', name: 'Plumbing', price: '₹199', rating: 4.6, jobs: '2.3K', desc: 'Leak repair, pipe fitting, tap installation, drainage issues'),
  ServiceOffering(slug: 'electrician', emoji: '⚡', name: 'Electrician', price: '₹199', rating: 4.7, jobs: '3.1K', desc: 'Wiring, switch repair, fan installation, MCB issues'),
  ServiceOffering(slug: 'ac-service', emoji: '❄️', name: 'AC Service', price: '₹399', rating: 4.8, jobs: '1.8K', desc: 'AC cleaning, gas refill, repair, installation & uninstallation'),
  ServiceOffering(slug: 'painting', emoji: '🎨', name: 'Home Painting', price: '₹999', rating: 4.5, jobs: '920', desc: 'Interior painting, exterior, texture, waterproofing'),
  ServiceOffering(slug: 'cleaning', emoji: '🧹', name: 'Home Cleaning', price: '₹499', rating: 4.7, jobs: '4.2K', desc: 'Deep cleaning, sofa/carpet cleaning, bathroom sanitization'),
  ServiceOffering(slug: 'carpentry', emoji: '🚪', name: 'Carpentry', price: '₹299', rating: 4.4, jobs: '1.1K', desc: 'Door repair, furniture assembly, wardrobe fitting'),
  ServiceOffering(slug: 'upvc-windows', emoji: '🪟', name: 'UPVC Windows', price: 'Free Quote', rating: 4.9, jobs: '650', desc: 'UPVC window installation, repair, replacement — Spectra profiles'),
  ServiceOffering(slug: 'cctv', emoji: '📷', name: 'CCTV Install', price: '₹799', rating: 4.6, jobs: '880', desc: 'CCTV installation, DVR setup, camera repair, remote viewing'),
  ServiceOffering(slug: 'locksmith', emoji: '🔒', name: 'Locksmith', price: '₹199', rating: 4.5, jobs: '1.4K', desc: 'Lock repair, key duplicate, door lock replacement'),
  ServiceOffering(slug: 'bathroom', emoji: '🛁', name: 'Bathroom Renovation', price: '₹4999', rating: 4.7, jobs: '340', desc: 'Full bathroom remodel, tile work, sanitary fitting'),
];

final Map<String, ServiceDetail> serviceDetails = {
  'plumbing': const ServiceDetail(
    emoji: '🔧',
    name: 'Plumbing',
    price: '₹199',
    color: AppColors.brand,
    rating: 4.6,
    jobs: '2.3K',
    desc: 'Our certified plumbers handle all types of plumbing issues — from minor leaks to complete pipe replacements.',
    packages: [
      ServicePackage(name: 'Basic Fix', price: '₹199', includes: ['Single leak repair', 'Tap replacement', 'Toilet flush fix', 'Upto 1 hour']),
      ServicePackage(name: 'Standard', price: '₹399', includes: ['Multiple leak repairs', 'Pipe fitting', 'Basin installation', 'Upto 2 hours']),
      ServicePackage(name: 'Full Service', price: '₹799', includes: ['Full bathroom plumbing check', 'All repairs included', 'New installations', 'Upto 4 hours']),
    ],
    faqs: [
      ServiceFaq('How long does it take?', 'Most jobs complete in 1-2 hours. Complex jobs may take longer.'),
      ServiceFaq('Are your plumbers verified?', 'Yes, all professionals are background-verified and trained.'),
      ServiceFaq("What if the problem isn't fixed?", "We offer a 30-day service guarantee. We'll return for free."),
    ],
  ),
  'upvc-windows': const ServiceDetail(
    emoji: '🪟',
    name: 'UPVC Windows',
    price: 'Free Quote',
    color: AppColors.brand,
    rating: 4.9,
    jobs: '650',
    desc: 'Premium UPVC window installation using Spectra profiles. Best quality, weather-resistant, noise-proof windows for homes and offices.',
    packages: [
      ServicePackage(name: 'Single Window', price: 'Free Quote', includes: ['Site visit & measurement', 'Custom fabrication', 'Professional installation', '1 year warranty']),
      ServicePackage(name: 'Full Home (upto 10 windows)', price: 'Free Quote', includes: ['All windows measured', 'Bulk discount applicable', 'Priority installation', '2 year warranty']),
      ServicePackage(name: 'Commercial Project', price: 'Free Quote', includes: ['Project consultation', 'Large scale installation', 'Dedicated project manager', '5 year warranty']),
    ],
    faqs: [
      ServiceFaq('What profiles do you use?', 'We use Spectra UPVC profiles — ISO certified, weather-resistant, UV-stable.'),
      ServiceFaq('How long does installation take?', '1-2 windows per day. Full home project takes 3-5 days.'),
      ServiceFaq('Do you provide warranty?', 'Yes, 1-5 year warranty depending on package. Manufacturing warranty also included.'),
    ],
  ),
  'electrician': const ServiceDetail(
    emoji: '⚡',
    name: 'Electrician',
    price: '₹199',
    color: AppColors.brand,
    rating: 4.7,
    jobs: '3.1K',
    desc: 'Certified electricians for all your electrical needs — from simple switch repairs to complete rewiring.',
    packages: [
      ServicePackage(name: 'Basic', price: '₹199', includes: ['Switch/socket repair', 'Fan installation', 'Light fitting', 'Upto 1 hour']),
      ServicePackage(name: 'Standard', price: '₹499', includes: ['Wiring repair', 'MCB/DB work', 'Multiple points', 'Upto 3 hours']),
      ServicePackage(name: 'Full Home', price: '₹1499', includes: ['Complete electrical check', 'All repairs', 'Safety audit', 'Full day']),
    ],
    faqs: [
      ServiceFaq('Are they certified electricians?', 'Yes, all are licensed and certified electricians.'),
      ServiceFaq('What safety measures do you take?', 'Full insulated tools, safety gear, and proper shutdowns.'),
      ServiceFaq('What is the service guarantee?', '30-day workmanship warranty on all jobs.'),
    ],
  ),
};

const ServiceDetail defaultServiceDetail = ServiceDetail(
  emoji: '🛠️',
  name: 'Service',
  price: '₹299',
  color: AppColors.brand,
  rating: 4.5,
  jobs: '500+',
  desc: 'Professional service by verified experts.',
  packages: [
    ServicePackage(name: 'Basic', price: '₹299', includes: ['Standard service', 'Quality guaranteed', '30-day warranty']),
  ],
  faqs: [ServiceFaq('Is there a guarantee?', 'Yes, 30 day workmanship warranty.')],
);

ServiceDetail serviceDetailFor(String slug) => serviceDetails[slug] ?? defaultServiceDetail;

