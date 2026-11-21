import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:razorpay_flutter/razorpay_flutter.dart';

Map<dynamic, dynamic> _toMap(JSAny? value) {
  final converted = value.dartify();
  return converted is Map
      ? Map<dynamic, dynamic>.from(converted)
      : <dynamic, dynamic>{};
}

void openWebRazorpayCheckout({
  required Map<String, dynamic> options,
  required void Function(PaymentSuccessResponse response) onSuccess,
  required void Function(PaymentFailureResponse response) onFailure,
  void Function(ExternalWalletResponse response)? onExternalWallet,
}) {
  final constructor = globalContext['Razorpay'];
  if (constructor.isUndefinedOrNull) {
    throw StateError(
        'Razorpay Checkout did not load. Check your internet connection and try again.');
  }

  var completed = false;
  final webOptions = Map<String, dynamic>.from(options);
  // The Flutter native SDK accepts a preferred method string. Razorpay's
  // Standard Web Checkout chooses methods from the merchant configuration.
  webOptions.remove('method');
  final jsOptions = webOptions.jsify() as JSObject;
  final modalOptions = (options['modal'] is Map
          ? Map<String, dynamic>.from(options['modal'] as Map)
          : <String, dynamic>{})
      .jsify() as JSObject;

  final successHandler = ((JSAny? rawResponse) {
    if (completed) return;
    completed = true;
    onSuccess(PaymentSuccessResponse.fromMap(_toMap(rawResponse)));
  }).toJS;
  final dismissHandler = (() {
    if (completed) return;
    completed = true;
    onFailure(PaymentFailureResponse(
      Razorpay.PAYMENT_CANCELLED,
      'Payment was cancelled.',
      null,
    ));
  }).toJS;
  jsOptions['handler'] = successHandler;
  modalOptions['ondismiss'] = dismissHandler;
  jsOptions['modal'] = modalOptions;

  final checkout = (constructor as JSFunction)
      .callAsConstructorVarArgs<JSObject>([jsOptions]);
  final failureHandler = ((JSAny? rawResponse) {
    if (completed) return;
    completed = true;
    final response = _toMap(rawResponse);
    final error = _toMap(response['error']);
    final rawCode = error['code'] ?? response['code'];
    final description = error['description'] ??
        error['reason'] ??
        response['message'] ??
        'Razorpay could not complete this payment.';
    onFailure(PaymentFailureResponse(
      int.tryParse(rawCode?.toString() ?? '') ?? Razorpay.UNKNOWN_ERROR,
      description.toString(),
      error,
    ));
  }).toJS;
  checkout.callMethodVarArgs<JSAny?>(
    'on'.toJS,
    ['payment.failed'.toJS, failureHandler],
  );

  if (onExternalWallet != null) {
    final externalWalletHandler = ((JSAny? rawResponse) {
      onExternalWallet(ExternalWalletResponse.fromMap(_toMap(rawResponse)));
    }).toJS;
    checkout.callMethodVarArgs<JSAny?>(
      'on'.toJS,
      ['external_wallet'.toJS, externalWalletHandler],
    );
  }

  checkout.callMethodVarArgs<JSAny?>('open'.toJS);
}
