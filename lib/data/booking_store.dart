import '../models/service_offering.dart';

class BookingStore {
  BookingStore._();

  static final List<Booking> bookings = [
    Booking(
      id: 'seed-1',
      serviceName: 'Plumbing',
      packageName: 'Standard',
      providerName: 'Ramesh Kumar',
      amountLabel: '₹399',
      status: BookingStatus.paid,
      paymentId: 'pay_TEST482913',
      bookedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Booking(
      id: 'seed-2',
      serviceName: 'AC Service',
      packageName: 'Full Service',
      providerName: 'CoolAir Experts',
      amountLabel: '₹799',
      status: BookingStatus.paid,
      paymentId: 'pay_TEST117256',
      bookedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    Booking(
      id: 'seed-3',
      serviceName: 'Electrician',
      packageName: 'Basic Fix',
      providerName: 'Anil Electricals',
      amountLabel: '₹199',
      status: BookingStatus.failed,
      bookedAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    ),
    Booking(
      id: 'seed-4',
      serviceName: 'UPVC Windows',
      packageName: 'Single Window',
      providerName: 'Spectra Window Co.',
      amountLabel: 'Free Quote',
      status: BookingStatus.pending,
      bookedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Booking(
      id: 'seed-5',
      serviceName: 'Home Cleaning',
      packageName: 'Standard',
      providerName: 'SparkleHome Cleaners',
      amountLabel: '₹699',
      status: BookingStatus.paid,
      paymentId: 'pay_TEST903471',
      bookedAt: DateTime.now().subtract(const Duration(days: 4, hours: 6)),
    ),
  ];

  static void add(Booking booking) => bookings.insert(0, booking);
}
