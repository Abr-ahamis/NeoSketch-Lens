import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchlens/telemetry/device_beacon.dart';

void main() {
  test('Telegram message contains allow-listed app and device fields only', () {
    final message = buildTelegramBeaconMessage(
      jsonEncode({
        'sent_at': '2026-11-13T10:00:00Z',
        'app': {'name': 'SketchLens', 'version': '1.0.0', 'build': '1'},
        'device': {
          'platform': 'android',
          'manufacturer': 'Example',
          'brand': 'Example',
          'model': 'Phone',
          'os_version': '16',
        },
        'photo': 'private-image-data',
        'file_path': '/private/drawing.png',
      }),
    );

    expect(message, contains('SketchLens device beacon'));
    expect(message, contains('Example Example Phone'));
    expect(message, contains('android 16'));
    expect(message, contains('SketchLens 1.0.0 (1)'));
    expect(message, isNot(contains('private-image-data')));
    expect(message, isNot(contains('/private/drawing.png')));
  });
}
