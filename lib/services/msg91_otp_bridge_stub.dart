import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';

class Msg91OtpBridge {
  static const widgetId = String.fromEnvironment('MSG91_WIDGET_ID');
  static const widgetToken = String.fromEnvironment('MSG91_WIDGET_TOKEN');

  static bool get configured => widgetId.isNotEmpty && widgetToken.isNotEmpty;

  static void initialize(String phone) {
    if (configured) OTPWidget.initializeWidget(widgetId, widgetToken);
  }

  static Future<Map<String, dynamic>?> verify(String reqId, String otp) =>
      OTPWidget.verifyOTP({'reqId': reqId, 'otp': otp});
}
