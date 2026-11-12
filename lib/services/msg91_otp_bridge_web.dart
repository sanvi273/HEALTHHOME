import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class Msg91OtpBridge {
  static const widgetId = String.fromEnvironment('MSG91_WIDGET_ID');
  static const widgetToken = String.fromEnvironment('MSG91_WIDGET_TOKEN');
  static const _resultElementId = 'healthhome-msg91-result';
  static const _requestEvent = 'healthhome-msg91-verify';
  static const _completeEvent = 'healthhome-msg91-complete';

  static bool get configured => widgetId.isNotEmpty && widgetToken.isNotEmpty;

  static void initialize(String phone) {
    if (!configured) return;
    final body = html.document.body!;
    html.document.getElementById(_resultElementId)?.remove();
    body.append(html.DivElement()
      ..id = _resultElementId
      ..hidden = true);
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final identifier =
        RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? '91$digits' : digits;
    final config = jsonEncode({
      'widgetId': widgetId,
      'tokenAuth': widgetToken,
      'identifier': identifier,
      'exposeMethods': true,
    });
    final script = html.ScriptElement()
      ..text = '''
        (() => {
          const config = $config;
          window.initSendOTP(config);
          window.addEventListener('$_requestEvent', () => {
            const body = document.body.dataset;
            window.verifyOtp(Number(body.msg91Otp), data => {
              document.getElementById('$_resultElementId').dataset.response = JSON.stringify(data);
              window.dispatchEvent(new Event('$_completeEvent'));
            }, error => {
              document.getElementById('$_resultElementId').dataset.response = JSON.stringify({type:'error', message:String(error)});
              window.dispatchEvent(new Event('$_completeEvent'));
            }, body.msg91ReqId);
          });
        })();
      ''';
    body.append(script);
  }

  static Future<Map<String, dynamic>?> verify(String reqId, String otp) {
    final body = html.document.body!;
    final result =
        html.document.getElementById(_resultElementId) as html.DivElement?;
    if (result == null) return Future.value(null);
    result.dataset.remove('response');
    body.dataset['msg91Otp'] = otp;
    body.dataset['msg91ReqId'] = reqId;
    final completer = Completer<Map<String, dynamic>?>();
    late StreamSubscription<html.Event> subscription;
    subscription = html.window.on[_completeEvent].listen((_) {
      subscription.cancel();
      final raw = result.dataset['response'];
      result.dataset.remove('response');
      body.dataset.remove('msg91Otp');
      body.dataset.remove('msg91ReqId');
      if (raw == null) return completer.complete(null);
      final decoded = jsonDecode(raw);
      completer
          .complete(decoded is Map ? Map<String, dynamic>.from(decoded) : null);
    });
    html.window.dispatchEvent(html.Event(_requestEvent));
    return completer.future.timeout(const Duration(seconds: 25), onTimeout: () {
      subscription.cancel();
      result.dataset.remove('response');
      body.dataset.remove('msg91Otp');
      body.dataset.remove('msg91ReqId');
      return null;
    });
  }
}
