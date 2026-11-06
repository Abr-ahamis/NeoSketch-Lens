import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchlens/geometry/homography.dart';

void main() {
  test('homography maps the source unit square to target corners', () {
    final source = [Offset.zero, const Offset(1, 0), const Offset(1, 1), const Offset(0, 1)];
    final target = [const Offset(20, 30), const Offset(220, 40), const Offset(200, 330), const Offset(10, 280)];
    final transform = homographyTransform(source, target);
    for (var i = 0; i < 4; i++) {
      final mapped = MatrixUtils.transformPoint(transform, source[i]);
      expect(mapped.dx, closeTo(target[i].dx, 1e-6));
      expect(mapped.dy, closeTo(target[i].dy, 1e-6));
    }
  });

  test('rejects a folded quad', () {
    expect(
      isConvexQuad([Offset.zero, const Offset(1, 1), const Offset(1, 0), const Offset(0, 1)]),
      isFalse,
    );
  });
}
