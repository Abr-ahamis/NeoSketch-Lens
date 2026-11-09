import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

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

const _endpoint = String.fromEnvironment('SKETCHLENS_BEACON_URL');
const _sentKey = 'device_beacon_sent';

final deviceBeaconProvider = Provider<DeviceBeaconService>((ref) {
  final service = DeviceBeaconService(ref.watch(databaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Sends one device/app diagnostic to the configured owner relay.
/// The relay URL is supplied at build time; the Telegram bot token never ships
/// in this app. Pending records stay in SQLite until the relay accepts them.
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
    if (preferences.getBool(_sentKey) ?? false) return;
    if ((await _database.getPendingBeacons()).isNotEmpty) return;

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
    final pending = await _database.getPendingBeacons();
    if (pending.isEmpty) return;
    final endpointUri = Uri.tryParse(_endpoint);
    if (endpointUri == null ||
        endpointUri.scheme != 'https' ||
        endpointUri.host.isEmpty) {
      debugPrint(
        '[SketchLens] Device beacon is queued; configure a valid HTTPS relay URL.',
      );
      return;
    }

    final networks = await _connectivity.checkConnectivity();
    if (networks.every((result) => result == ConnectivityResult.none)) return;

    _sending = true;
    try {
      for (final beacon in pending) {
        await _client.post<void>(
          _endpoint,
          data: jsonDecode(beacon.payloadJson),
          options: Options(
            contentType: Headers.jsonContentType,
            headers: const {'X-SketchLens-Event': 'device_beacon'},
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );
        await _database.deleteBeacon(beacon.id);
        await (await _prefs()).setBool(_sentKey, true);
      }
      _retryCount = 0;
      _retryTimer?.cancel();
    } on DioException catch (error) {
      // Keep the payload local for retry. Never print its contents or endpoint.
      debugPrint(
        '[SketchLens] Device beacon delivery failed (${error.type.name}).',
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
