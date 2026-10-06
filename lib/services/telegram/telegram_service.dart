import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tdlib_ex/td_api.dart' as td;
import 'package:tdlib_ex/td_client.dart';

class TelegramService {
  TelegramService._();

  static final TelegramService instance = TelegramService._();

  Client? _client;

  StreamSubscription<td.TdObject>? _eventsSubscription;

  bool get isInitialized => _client != null;

  /// Telegram API ID
  ///
  /// API ID is okay to keep here.
  /// NEVER put your API HASH in source code.
  static const int apiId = 33312289;

static const String apiHash =
    String.fromEnvironment('TELEGRAM_API_HASH');

  /// ------------------------------------------------------------
  /// INITIALIZE TDLib
  /// ------------------------------------------------------------

  Future<void> initialize() async {
    if (_client != null) {
      debugPrint('========================================');
      debugPrint('TDLIB: Already initialized');
      debugPrint('========================================');
      return;
    }

    debugPrint('========================================');
    debugPrint('TDLIB: INITIALIZING');
    debugPrint('========================================');

    try {
      final Client client = Client.create();

      _client = client;

      _eventsSubscription = client.updates.listen(
        _handleEvent,
        onError: (error) {
          debugPrint('TDLIB UPDATE ERROR: $error');
        },
      );

      client.initialize();

      debugPrint('TDLIB: Client created');
      debugPrint('TDLIB: Waiting for authorization state...');
    } catch (e, stackTrace) {
      debugPrint('TDLIB INITIALIZATION ERROR: $e');
      debugPrint('$stackTrace');

      _client = null;

      rethrow;
    }
  }

  /// ------------------------------------------------------------
  /// HANDLE TDLib EVENTS
  /// ------------------------------------------------------------

  Future<void> _handleEvent(td.TdObject event) async {
    debugPrint(
      'TDLIB EVENT: ${event.runtimeType}',
    );

    if (event is td.UpdateConnectionState) {
      debugPrint(
        'TDLIB CONNECTION STATE: ${event.state.runtimeType}',
      );
    }

    if (event is td.UpdateAuthorizationState) {
      debugPrint(
        'TDLIB AUTHORIZATION STATE: '
        '${event.authorizationState.runtimeType}',
      );

      await _handleAuthorizationState(
        event.authorizationState,
      );
    }
  }

  /// ------------------------------------------------------------
  /// HANDLE AUTHORIZATION
  /// ------------------------------------------------------------

  Future<void> _handleAuthorizationState(
    td.AuthorizationState state,
  ) async {
    final client = _client;

    if (client == null) {
      return;
    }

    debugPrint(
      'TDLIB AUTH STATE: ${state.runtimeType}',
    );

    // ------------------------------------------------------------
    // STEP 1
    // TDLib needs API parameters
    // ------------------------------------------------------------

    if (state is td.AuthorizationStateWaitTdlibParameters) {
      debugPrint(
        'TDLIB: Sending TDLib parameters...',
      );

      final String filesDirectory =
          await _getFilesDirectory();

      final String databaseDirectory =
          await _getDatabaseDirectory();

      await client.send(
        td.SetTdlibParameters(
          systemVersion: Platform.operatingSystemVersion,
          useTestDc: false,
          useSecretChats: false,
          useMessageDatabase: true,
          useFileDatabase: true,
          useChatInfoDatabase: true,
          filesDirectory: filesDirectory,
          databaseDirectory: databaseDirectory,
          systemLanguageCode: 'en',
          deviceModel: 'HealthHome',
          applicationVersion: '1.0.0',
          apiId: apiId,
apiHash: apiHash,
          databaseEncryptionKey: '',
        ),
      );

      debugPrint(
        'TDLIB: Parameters sent',
      );

      return;
    }

    // ------------------------------------------------------------
    // STEP 2
    // TDLib asks for phone number
    // ------------------------------------------------------------

    if (state is td.AuthorizationStateWaitPhoneNumber) {
      debugPrint(
        'TDLIB: Waiting for phone number',
      );

      return;
    }

    // ------------------------------------------------------------
    // STEP 3
    // TDLib asks for OTP
    // ------------------------------------------------------------

    if (state is td.AuthorizationStateWaitCode) {
      debugPrint(
        'TDLIB: Waiting for Telegram OTP',
      );

      return;
    }

    // ------------------------------------------------------------
    // STEP 4
    // TDLib asks for 2FA password
    // ------------------------------------------------------------

    if (state is td.AuthorizationStateWaitPassword) {
      debugPrint(
        'TDLIB: Telegram 2FA password required',
      );

      return;
    }

    // ------------------------------------------------------------
    // STEP 5
    // USER AUTHORIZED
    // ------------------------------------------------------------

    if (state is td.AuthorizationStateReady) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'TDLIB: AUTHENTICATION SUCCESSFUL',
      );

      debugPrint(
        '========================================',
      );

      return;
    }

    // ------------------------------------------------------------
    // CLOSED
    // ------------------------------------------------------------

    if (state is td.AuthorizationStateClosed) {
      debugPrint(
        'TDLIB: Authorization state closed',
      );
    }
  }

  /// ------------------------------------------------------------
  /// GET CURRENT USER
  /// ------------------------------------------------------------

  Future<td.User?> getMe() async {
    final client = _client;

    if (client == null) {
      debugPrint(
        'TDLIB: Client not initialized',
      );

      return null;
    }

    try {
      final result =
          await client.send<td.User>(
        const td.GetMe(),
      );

      return result;
    } catch (e) {
      debugPrint(
        'TDLIB GET ME ERROR: $e',
      );

      return null;
    }
  }

  /// ------------------------------------------------------------
  /// SEND PHONE NUMBER
  /// ------------------------------------------------------------

  Future<void> sendPhoneNumber(
    String phoneNumber,
  ) async {
    final client = _client;

    if (client == null) {
      throw Exception(
        'TDLib is not initialized.',
      );
    }

    await client.send(
      td.SetAuthenticationPhoneNumber(
        phoneNumber: phoneNumber,
      ),
    );

    debugPrint(
      'TDLIB: Phone number submitted',
    );
  }

  /// ------------------------------------------------------------
  /// SEND OTP
  /// ------------------------------------------------------------

  Future<void> sendOtp(
    String code,
  ) async {
    final client = _client;

    if (client == null) {
      throw Exception(
        'TDLib is not initialized.',
      );
    }

    await client.send(
      td.CheckAuthenticationCode(
        code: code,
      ),
    );

    debugPrint(
      'TDLIB: OTP submitted',
    );
  }

  /// ------------------------------------------------------------
  /// SEND 2FA PASSWORD
  /// ------------------------------------------------------------

  Future<void> sendPassword(
    String password,
  ) async {
    final client = _client;

    if (client == null) {
      throw Exception(
        'TDLib is not initialized.',
      );
    }

    await client.send(
      td.CheckAuthenticationPassword(
        password: password,
      ),
    );

    debugPrint(
      'TDLIB: 2FA password submitted',
    );
  }

  /// ------------------------------------------------------------
  /// GET FILES DIRECTORY
  /// ------------------------------------------------------------

  Future<String> _getFilesDirectory() async {
    if (kIsWeb) {
      return 'files';
    }

    final Directory directory =
        await getApplicationSupportDirectory();

    final String path =
        '${directory.path}/telegram/files';

    await Directory(path).create(
      recursive: true,
    );

    return path;
  }

  /// ------------------------------------------------------------
  /// GET DATABASE DIRECTORY
  /// ------------------------------------------------------------

  Future<String> _getDatabaseDirectory() async {
    if (kIsWeb) {
      return 'database';
    }

    final Directory directory =
        await getApplicationSupportDirectory();

    final String path =
        '${directory.path}/telegram/database';

    await Directory(path).create(
      recursive: true,
    );

    return path;
  }

  /// ------------------------------------------------------------
  /// DESTROY
  /// ------------------------------------------------------------

  Future<void> destroy() async {
    debugPrint(
      'TDLIB: Destroying client...',
    );

    await _eventsSubscription?.cancel();

    _eventsSubscription = null;

    _client?.destroy();

    _client = null;

    debugPrint(
      'TDLIB: Client destroyed',
    );
  }
}