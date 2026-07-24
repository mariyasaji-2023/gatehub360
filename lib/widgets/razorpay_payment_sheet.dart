import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/auth_service.dart';
import '../services/payments_api.dart';

enum PaymentOutcome { success, failed, cancelled }

class PaymentResult {
  final PaymentOutcome outcome;
  final String? paymentId;

  const PaymentResult({required this.outcome, this.paymentId});
}

double? _parseRupees(String label) {
  final digits = label.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits);
}

/// Opens the real Razorpay checkout (Test Mode keys configured on the
/// backend) for the given amount, creates the order via our backend,
/// and verifies the payment signature after completion.
Future<PaymentResult> showRazorpayCheckout({
  required BuildContext context,
  required String description,
  required String amountLabel,
}) async {
  final amountRupees = _parseRupees(amountLabel);
  if (amountRupees == null) {
    return const PaymentResult(outcome: PaymentOutcome.failed);
  }

  late final RazorpayOrder order;
  try {
    order = await PaymentsApi.createOrder(amountRupees: amountRupees, receipt: description);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return const PaymentResult(outcome: PaymentOutcome.failed);
  }

  final completer = Completer<PaymentResult>();
  final razorpay = Razorpay();

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
    if (completer.isCompleted) return;
    bool verified = false;
    try {
      verified = await PaymentsApi.verify(
        orderId: response.orderId ?? order.orderId,
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
    } catch (_) {
      verified = false;
    }
    completer.complete(PaymentResult(
      outcome: verified ? PaymentOutcome.success : PaymentOutcome.failed,
      paymentId: response.paymentId,
    ));
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    if (completer.isCompleted) return;
    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    completer.complete(PaymentResult(outcome: cancelled ? PaymentOutcome.cancelled : PaymentOutcome.failed));
  });

  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
    if (completer.isCompleted) return;
    completer.complete(const PaymentResult(outcome: PaymentOutcome.cancelled));
  });

  final firebaseUser = FirebaseAuth.instance.currentUser;
  try {
    razorpay.open({
      'key': order.keyId,
      'order_id': order.orderId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': 'GateHub360',
      'description': description,
      'prefill': {
        if (firebaseUser?.email != null) 'email': firebaseUser!.email,
        if (firebaseUser?.phoneNumber != null) 'contact': firebaseUser!.phoneNumber,
      },
      'theme': {'color': '#1D82EA'},
    });
  } catch (_) {
    razorpay.clear();
    return const PaymentResult(outcome: PaymentOutcome.failed);
  }

  final result = await completer.future;
  razorpay.clear();
  return result;
}
