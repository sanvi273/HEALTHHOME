import 'package:razorpay_flutter/razorpay_flutter.dart';

void openWebRazorpayCheckout({
  required Map<String, dynamic> options,
  required void Function(PaymentSuccessResponse response) onSuccess,
  required void Function(PaymentFailureResponse response) onFailure,
  void Function(ExternalWalletResponse response)? onExternalWallet,
}) {
  throw UnsupportedError('Browser Razorpay checkout is not available on this platform.');
}
