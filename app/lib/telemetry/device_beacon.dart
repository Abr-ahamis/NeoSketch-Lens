import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/project_repository.dart';

const _telegramBotToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN');
const _telegramChatId = String.fromEnvironment('TELEGRAM_CHAT_ID');
const _relayUrl = String.fromEnvironment('SKETCHLENS_BEACON_URL');
const _sentKey = 'device_beacon_sent_v2';

final deviceBeaconProvider = Provider<DeviceBeaconService>((ref) {
  final service = DeviceBeaconService(ref.watch(databaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Sends one device/app diagnostic to Telegram directly or through the relay.
/// Private personal APK builds inject credentials from server/.env. Shared APKs
/// can use the HTTPS relay so its Telegram token stays off-device.
class DeviceBeaconService {
  DeviceBeaconService(
    this._database, {
    Dio? client,
    Connectivity? connectivity,
    this._preferences,
  }) : _client = client ?? Dio(),
       _connectivity = connectivity ?? Connectivity();

  final AppDatabase _database;
  final Dio _client;
  final Connectivity _connectivity;
  SharedPreferences? _preferences;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _started = false;
  bool _sending = false;
  int _retryCount = 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    debugPrint('[SketchLens] Device beacon service started.');
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          unawaited(flush());
        }
      },
      onError: (Object error) {
        debugPrint('[SketchLens] Beacon network monitor failed.');
      },
    );
    try {
      await _queueIfNeeded();
      await flush();
    } catch (error) {
      debugPrint(
        '[SketchLens] Could not prepare device beacon (${error.runtimeType}).',
      );
      _scheduleRetry();
    }
  }

  Future<void> _queueIfNeeded() async {
    final preferences = await _prefs();
    if (preferences.getBool(_sentKey) ?? false) {
      debugPrint(
        '[SketchLens] Device beacon was already sent for this install.',
      );
      return;
    }
    if ((await _database.getPendingBeacons()).isNotEmpty) {
      debugPrint('[SketchLens] Retrying a queued device beacon.');
      return;
    }

    final package = await PackageInfo.fromPlatform();
    final platform = await _platformInfo();
    final payload = <String, Object?>{
      'event_id': const Uuid().v4(),
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'app': {
        'name': package.appName,
        'version': package.version,
        'build': package.buildNumber,
      },
      'device': platform,
    };
    final id = payload['event_id']! as String;
    await _database.enqueueBeacon(id, jsonEncode(payload));
    debugPrint('[SketchLens] Queued the one-time device beacon.');
  }

  Future<Map<String, Object?>> _platformInfo() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return {
        'platform': 'android',
        'manufacturer': info.manufacturer,
        'brand': info.brand,
        'model': info.model,
        'os_version': info.version.release,
        'api_level': info.version.sdkInt,
      };
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return {
        'platform': 'ios',
        'model': info.model,
        'os_version': info.systemVersion,
      };
    }
    return {'platform': defaultTargetPlatform.name};
  }

  Future<void> flush() async {
    if (_sending) return;
    _sending = true;
    var pending = <BeaconQueueData>[];
    try {
      pending = await _database.getPendingBeacons();
      if (pending.isEmpty) {
        debugPrint('[SketchLens] No pending device beacon to send.');
        return;
      }
      final directTelegram =
          _telegramBotToken.isNotEmpty && _telegramChatId.isNotEmpty;
      final relay = Uri.tryParse(_relayUrl);
      if (!directTelegram &&
          (relay == null || relay.scheme != 'https' || relay.host.isEmpty)) {
        debugPrint(
          '[SketchLens] Device beacon is queued; configure Telegram credentials or an HTTPS relay.',
        );
        return;
      }

      for (final beacon in pending) {
        debugPrint(
          '[SketchLens] Sending device beacon via ${directTelegram ? 'Telegram' : 'relay'}.',
        );
        final response = await _client.post<Map<String, dynamic>>(
          directTelegram
              ? 'https://api.telegram.org/bot$_telegramBotToken/sendMessage'
              : relay.toString(),
          data: directTelegram
              ? {
                  'chat_id': _telegramChatId,
                  'text': buildTelegramBeaconMessage(beacon.payloadJson),
                  'disable_web_page_preview': true,
                }
              : jsonDecode(beacon.payloadJson),
          options: Options(
            contentType: directTelegram
                ? Headers.formUrlEncodedContentType
                : Headers.jsonContentType,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );
        if (directTelegram && response.data?['ok'] != true) {
          throw const FormatException('Telegram rejected the beacon.');
        }
        debugPrint(
          '[SketchLens] Device beacon accepted by ${directTelegram ? 'Telegram' : 'relay'} (HTTP ${response.statusCode ?? 'unknown'}).',
        );
        await _database.deleteBeacon(beacon.id);
        await (await _prefs()).setBool(_sentKey, true);
      }
      _retryCount = 0;
      _retryTimer?.cancel();
    } on DioException catch (error) {
      // Keep the payload local for retry. Never print its contents or endpoint.
      final responseData = error.response?.data;
      final telegramCode = responseData is Map
          ? responseData['error_code']
          : null;
      final telegramDescription = responseData is Map
          ? responseData['description']
          : null;
      final cause = error.error;
      final details = [
        if (error.response?.statusCode case final status?) 'HTTP $status',
        if (telegramCode != null) 'Telegram code $telegramCode',
        if (telegramDescription is String)
          telegramDescription.replaceAll(_telegramBotToken, '[redacted]'),
        if (cause is SocketException)
          'socket ${cause.osError?.errorCode ?? 'error'}: ${cause.message.replaceAll(_telegramBotToken, '[redacted]')}',
        if (cause != null && cause is! SocketException)
          'transport ${cause.runtimeType}',
      ].join(', ');
      debugPrint(
        '[SketchLens] Device beacon delivery failed: ${details.isEmpty ? error.type.name : details}.',
      );
      for (final beacon in pending) {
        await _database.incrementBeaconAttempts(beacon.id);
      }
      _scheduleRetry();
    } catch (error) {
      debugPrint(
        '[SketchLens] Device beacon delivery failed (${error.runtimeType}).',
      );
      _scheduleRetry();
    } finally {
      _sending = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryCount = (_retryCount + 1).clamp(1, 8);
    final seconds = (15 * (1 << (_retryCount - 1))).clamp(15, 3600);
    _retryTimer = Timer(Duration(seconds: seconds), () => unawaited(flush()));
  }

  Future<SharedPreferences> _prefs() async =>
      _preferences ??= await SharedPreferences.getInstance();

  void dispose() {
    _retryTimer?.cancel();
    unawaited(_connectivitySubscription?.cancel());
    _client.close();
  }
}

/// Builds the allow-listed text sent to Telegram. Images and unknown payload
/// fields are deliberately excluded.
String buildTelegramBeaconMessage(String payloadJson) {
  final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
  final app = payload['app'] as Map<String, dynamic>;
  final device = payload['device'] as Map<String, dynamic>;
  String field(Map<String, dynamic> values, String key) =>
      values[key]?.toString() ?? 'Unknown';

  return [
    'SketchLens device beacon',
    'Device: ${field(device, 'manufacturer')} ${field(device, 'brand')} ${field(device, 'model')}',
    'Platform: ${field(device, 'platform')} ${field(device, 'os_version')}',
    'App: ${field(app, 'name')} ${field(app, 'version')} (${field(app, 'build')})',
    'Queued at: ${field(payload, 'sent_at')}',
  ].join('\n');
}
