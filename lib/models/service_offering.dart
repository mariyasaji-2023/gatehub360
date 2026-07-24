import 'package:flutter/material.dart';

class ServiceOffering {
  final String slug;
  final String emoji;
  final String name;
  final String price;
  final double rating;
  final String jobs;
  final String desc;

  const ServiceOffering({
    required this.slug,
    required this.emoji,
    required this.name,
    required this.price,
    required this.rating,
    required this.jobs,
    required this.desc,
  });
}

class ServicePackage {
  final String name;
  final String price;
  final List<String> includes;

  const ServicePackage({required this.name, required this.price, required this.includes});
}

class ServiceFaq {
  final String question;
  final String answer;

  const ServiceFaq(this.question, this.answer);
}

class MyServiceListing {
  final String id;
  final String categorySlug;
  final String emoji;
  final String name;
  final String price;
  final String desc;
  final bool active;
  final String? providerName;

  const MyServiceListing({
    required this.id,
    required this.categorySlug,
    required this.emoji,
    required this.name,
    required this.price,
    required this.desc,
    this.active = true,
    this.providerName,
  });

  factory MyServiceListing.fromJson(Map<String, dynamic> json, {required String emoji, required String name}) =>
      MyServiceListing(
        id: json['_id'] as String,
        categorySlug: json['categorySlug'] as String,
        emoji: emoji,
        name: name,
        price: json['price'] as String,
        desc: json['desc'] as String,
        active: json['active'] as bool? ?? true,
        providerName: json['providerName'] as String?,
      );

  MyServiceListing copyWith({String? emoji, String? name, String? price, String? desc, bool? active}) =>
      MyServiceListing(
        id: id,
        categorySlug: categorySlug,
        emoji: emoji ?? this.emoji,
        name: name ?? this.name,
        price: price ?? this.price,
        desc: desc ?? this.desc,
        active: active ?? this.active,
        providerName: providerName,
      );
}

enum BookingStatus { paid, pending, failed }

class Booking {
  final String id;
  final String serviceName;
  final String packageName;
  final String providerName;
  final String amountLabel;
  final BookingStatus status;
  final String? paymentId;
  final DateTime bookedAt;

  const Booking({
    required this.id,
    required this.serviceName,
    required this.packageName,
    required this.providerName,
    required this.amountLabel,
    required this.status,
    this.paymentId,
    required this.bookedAt,
  });
}

class ServiceDetail {
  final String emoji;
  final String name;
  final String price;
  final Color color;
  final double rating;
  final String jobs;
  final String desc;
  final List<ServicePackage> packages;
  final List<ServiceFaq> faqs;

  const ServiceDetail({
    required this.emoji,
    required this.name,
    required this.price,
    required this.color,
    required this.rating,
    required this.jobs,
    required this.desc,
    required this.packages,
    required this.faqs,
  });
}
