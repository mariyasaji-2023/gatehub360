import '../models/hostel_listing.dart';
import '../models/property_listing.dart';
import '../models/service_offering.dart';
import '../theme/app_theme.dart';

const List<HostelListing> hostelListings = [
  HostelListing(
    id: 1,
    emoji: '🏠',
    title: 'Sri Rama PG for Men',
    location: 'Miyapur, Hyderabad',
    price: '4,500',
    type: 'PG',
    gender: 'Men',
    amenities: ['WiFi', 'AC', 'Food', 'Parking'],
    badge: 'Verified',
    rating: 4.5,
    reviews: 28,
  ),
  HostelListing(
    id: 2,
    emoji: '🏡',
    title: 'Lakshmi Ladies Hostel',
    location: 'Banjara Hills, Hyderabad',
    price: '6,000',
    type: 'Hostel',
    gender: 'Women',
    amenities: ['WiFi', 'Laundry', 'Food', 'Geyser'],
    badge: 'Available',
    rating: 4.7,
    reviews: 43,
  ),
  HostelListing(
    id: 3,
    emoji: '🏢',
    title: 'Comfort Service Apartment',
    location: 'Whitefield, Bangalore',
    price: '12,000',
    type: 'Service Apt',
    gender: 'Any',
    amenities: ['AC', 'Kitchen', 'Parking', 'WiFi'],
    badge: 'Verified',
    rating: 4.3,
    reviews: 19,
  ),
  HostelListing(
    id: 4,
    emoji: '🏘️',
    title: 'Sai Krishna Boys PG',
    location: 'Kukatpally, Hyderabad',
    price: '3,800',
    type: 'PG',
    gender: 'Men',
    amenities: ['WiFi', 'Food', 'Laundry'],
    badge: 'Available',
    rating: 4.1,
    reviews: 15,
  ),
  HostelListing(
    id: 5,
    emoji: '🏠',
    title: 'Green Valley Women PG',
    location: 'HSR Layout, Bangalore',
    price: '7,500',
    type: 'PG',
    gender: 'Women',
    amenities: ['WiFi', 'AC', 'Food', 'Gym'],
    badge: 'Verified',
    rating: 4.8,
    reviews: 61,
  ),
  HostelListing(
    id: 6,
    emoji: '🏢',
    title: 'Executive Studio Flat',
    location: 'Gachibowli, Hyderabad',
    price: '15,000',
    type: 'Flat',
    gender: 'Any',
    amenities: ['AC', 'Kitchen', 'Parking', 'Security'],
    badge: 'Premium',
    rating: 4.6,
    reviews: 32,
  ),
];

const List<String> hostelFilters = ['All', 'PG', 'Hostel', 'Service Apt', 'Flat', 'For Men', 'For Women'];

const List<({String icon, String title, String desc})> hostelOwnerFeatures = [
  (icon: '🛏️', title: 'Bed-Wise Management', desc: 'Track every bed in every room. Occupancy, vacancies, upcoming checkouts at a glance.'),
  (icon: '💰', title: 'Rent Auto-Reminders', desc: 'Automatic WhatsApp & SMS reminders to tenants on due dates.'),
  (icon: '🍽️', title: 'Food Menu & Mess', desc: 'Manage daily menu, meal preferences, and mess billing from one dashboard.'),
  (icon: '📋', title: 'Digital Check-In/Out', desc: 'Paperless check-in with ID proof upload and deposit tracking.'),
  (icon: '📊', title: 'Revenue Dashboard', desc: 'Track monthly income, expenses, occupancy and profitability.'),
  (icon: '📱', title: 'Tenant App', desc: 'Tenants raise complaints, view bills, pay rent, communicate via app.'),
];

const List<({String step, String title, String desc})> hostelHowItWorks = [
  (step: '1', title: 'Search & Filter', desc: 'Enter location, budget & preferences to find matching PGs instantly'),
  (step: '2', title: 'View & Compare', desc: 'See photos, amenities, reviews and compare multiple options'),
  (step: '3', title: 'Visit & Book', desc: 'Schedule a visit or book directly through app with instant confirmation'),
  (step: '4', title: 'Move In', desc: 'Digital check-in, pay rent online, raise complaints via GateHub360 app'),
];

final Map<int, HostelDetail> hostelDetails = {
  1: const HostelDetail(
    id: 1,
    emoji: '🏠',
    title: 'Sri Rama PG for Men',
    location: 'Miyapur, Hyderabad',
    price: '4,500',
    type: 'PG',
    gender: 'Men',
    amenities: ['WiFi', 'AC', 'Food', 'Parking', 'Geyser', 'Laundry'],
    badge: 'Verified',
    rating: 4.5,
    reviews: 28,
    owner: 'Rama Rao',
    phone: '+91 98765 43210',
    rooms: [
      HostelRoomOption(name: 'Single AC', price: '5500', available: 2),
      HostelRoomOption(name: 'Double Sharing', price: '4500', available: 4),
      HostelRoomOption(name: 'Triple Sharing', price: '3500', available: 1),
    ],
    rules: ['No smoking', 'No alcohol', 'Curfew 11 PM', 'ID proof mandatory'],
    about: 'Sri Rama PG is one of the most trusted PGs in Miyapur. With 15 years of operation, we provide clean, safe, and comfortable accommodation for working professionals and students.',
    nearby: ['500m — Metro Station', '200m — Supermarket', '1.2km — Hitech City'],
  ),
  2: const HostelDetail(
    id: 2,
    emoji: '🏡',
    title: 'Lakshmi Ladies Hostel',
    location: 'Banjara Hills, Hyderabad',
    price: '6,000',
    type: 'Hostel',
    gender: 'Women',
    amenities: ['WiFi', 'Laundry', 'Food', 'Geyser', 'Security', 'Gym'],
    badge: 'Available',
    rating: 4.7,
    reviews: 43,
    owner: 'Lakshmi Devi',
    phone: '+91 87654 32109',
    rooms: [
      HostelRoomOption(name: 'Single Room', price: '8000', available: 1),
      HostelRoomOption(name: 'Double Sharing', price: '6000', available: 3),
    ],
    rules: ['Ladies only', 'No male visitors', 'In by 10 PM'],
    about: 'Safe and secure ladies hostel in the heart of Banjara Hills. 24/7 security, nutritious food, and all amenities included.',
    nearby: ['300m — Bus Stop', '1km — Park', '2km — Mall'],
  ),
  3: const HostelDetail(
    id: 3,
    emoji: '🏢',
    title: 'Comfort Service Apartment',
    location: 'Whitefield, Bangalore',
    price: '12,000',
    type: 'Service Apt',
    gender: 'Any',
    amenities: ['AC', 'Kitchen', 'Parking', 'WiFi', 'Security', 'TV'],
    badge: 'Verified',
    rating: 4.3,
    reviews: 19,
    owner: 'Sundar Kumar',
    phone: '+91 76543 21098',
    rooms: [
      HostelRoomOption(name: '1BHK Studio', price: '12000', available: 2),
      HostelRoomOption(name: '2BHK Apartment', price: '18000', available: 1),
    ],
    rules: ['No parties', 'Pets allowed', 'Minimum 3 month stay'],
    about: 'Modern service apartments with full kitchen and all amenities. Perfect for professionals on long-term assignments.',
    nearby: ['100m — Mall of Whitefield', '500m — IT Park', '1km — Metro'],
  ),
};

HostelDetail hostelDetailFor(int id) => hostelDetails[id] ?? hostelDetails[1]!;

const List<PropertyListing> propertyListings = [
  PropertyListing(id: 1, emoji: '🏙️', title: 'Prestige Lakeside Habitat', location: 'Whitefield, Bangalore', price: '85L', type: 'Apartment', bhk: '3 BHK', sqft: '1450', status: 'Ready to Move', badge: 'RERA'),
  PropertyListing(id: 2, emoji: '🏠', title: 'NCC Urban One', location: 'Kokapet, Hyderabad', price: '1.2Cr', type: 'Apartment', bhk: '4 BHK', sqft: '2100', status: 'Under Construction', badge: 'Builder Direct'),
  PropertyListing(id: 3, emoji: '🏡', title: 'Independent Villa', location: 'Kompally, Hyderabad', price: '65L', type: 'Villa', bhk: '3 BHK', sqft: '2400', status: 'Ready to Move', badge: 'Verified'),
  PropertyListing(id: 4, emoji: '🏢', title: 'Aparna CyberZon', location: 'HITEC City, Hyderabad', price: '92L', type: 'Apartment', bhk: '2 BHK', sqft: '1120', status: 'New Launch', badge: 'RERA'),
  PropertyListing(id: 5, emoji: '🌳', title: 'Residential Plot', location: 'Bachupally, Hyderabad', price: '28L', type: 'Plot', bhk: 'N/A', sqft: '200 sqyd', status: 'Available', badge: 'GHMC'),
  PropertyListing(id: 6, emoji: '🏬', title: 'Office Space for Rent', location: 'Gachibowli, Hyderabad', price: '45K/mo', type: 'Commercial', bhk: 'N/A', sqft: '1800', status: 'Available', badge: 'Furnished'),
  PropertyListing(id: 7, emoji: '🏘️', title: 'Sobha Dream Acres', location: 'Panathur, Bangalore', price: '55L', type: 'Apartment', bhk: '2 BHK', sqft: '990', status: 'Ready to Move', badge: 'RERA'),
  PropertyListing(id: 8, emoji: '🏚️', title: 'Row House', location: 'Tellapur, Hyderabad', price: '48L', type: 'Villa', bhk: '3 BHK', sqft: '1800', status: 'Ready to Move', badge: 'Verified'),
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

final Map<int, PropertyDetail> propertyDetails = {
  1: const PropertyDetail(
    id: 1,
    emoji: '🏙️',
    title: 'Prestige Lakeside Habitat',
    location: 'Whitefield, Bangalore',
    price: '85L',
    type: 'Apartment',
    bhk: '3 BHK',
    sqft: '1450',
    floor: '12th of 24',
    status: 'Ready to Move',
    badge: 'RERA Verified',
    builder: 'Prestige Group',
    facing: 'East',
    age: 'New',
    about: 'Premium 3 BHK apartments with lake view in the heart of Whitefield. World-class amenities, great connectivity.',
    amenities: ['Swimming Pool', 'Clubhouse', 'Gym', 'Children Play Area', '24/7 Security', 'Power Backup', 'Covered Parking', 'Garden'],
    priceBreakdown: PropertyPriceBreakdown(base: '₹75L', registration: '₹4L', other: '₹6L', total: '₹85L'),
    contact: '+91 90000 00001',
  ),
  2: const PropertyDetail(
    id: 2,
    emoji: '🏠',
    title: 'NCC Urban One',
    location: 'Kokapet, Hyderabad',
    price: '1.2Cr',
    type: 'Apartment',
    bhk: '4 BHK',
    sqft: '2100',
    floor: '8th of 30',
    status: 'Under Construction',
    badge: 'RERA Verified',
    builder: 'NCC Urban',
    facing: 'North',
    age: 'Possession: Dec 2026',
    about: 'Luxury 4 BHK apartments in the fastest growing corridor of Hyderabad. Panoramic views, top-notch construction.',
    amenities: ['Infinity Pool', 'Sky Lounge', 'Gym', 'Yoga Deck', 'EV Charging', 'Smart Home'],
    priceBreakdown: PropertyPriceBreakdown(base: '₹1.0Cr', registration: '₹8L', other: '₹12L', total: '₹1.2Cr'),
    contact: '+91 90000 00002',
  ),
};

PropertyDetail propertyDetailFor(int id) => propertyDetails[id] ?? propertyDetails[1]!;

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

