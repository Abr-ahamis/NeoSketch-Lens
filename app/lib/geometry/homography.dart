import 'dart:math' as math;

import 'package:flutter/widgets.dart';
Matrix4 homographyTransform(List<Offset> source, List<Offset> destination) {
  if (source.length != 4 || destination.length != 4) {
    throw ArgumentError('A perspective transform needs four source and target points.');
  }

  final rows = <List<double>>[];
  final values = <double>[];
  for (var i = 0; i < 4; i++) {
    final x = source[i].dx;
    final y = source[i].dy;
    final u = destination[i].dx;
    final v = destination[i].dy;
    rows.add([x, y, 1, 0, 0, 0, -u * x, -u * y]);
    values.add(u);
    rows.add([0, 0, 0, x, y, 1, -v * x, -v * y]);
    values.add(v);
  }

  final h = _solve(rows, values);
  final matrix = Matrix4.identity();
  matrix
    ..setEntry(0, 0, h[0])
    ..setEntry(0, 1, h[1])
    ..setEntry(0, 3, h[2])
    ..setEntry(1, 0, h[3])
    ..setEntry(1, 1, h[4])
    ..setEntry(1, 3, h[5])
    ..setEntry(3, 0, h[6])
    ..setEntry(3, 1, h[7]);
  return matrix;
}

List<double> _solve(List<List<double>> matrix, List<double> values) {
  const count = 8;
  final augmented = List.generate(
    count,
    (row) => [...matrix[row], values[row]],
  );

  for (var column = 0; column < count; column++) {
    var pivot = column;
    for (var row = column + 1; row < count; row++) {
      if (augmented[row][column].abs() > augmented[pivot][column].abs()) {
        pivot = row;
      }
    }
    if (augmented[pivot][column].abs() < 1e-10) {
      throw ArgumentError('The selected paper corners do not form a transformable quad.');
    }
    final swap = augmented[column];
    augmented[column] = augmented[pivot];
    augmented[pivot] = swap;

    final divisor = augmented[column][column];
    for (var j = column; j <= count; j++) {
      augmented[column][j] /= divisor;
    }
    for (var row = 0; row < count; row++) {
      if (row == column) continue;
      final factor = augmented[row][column];
      for (var j = column; j <= count; j++) {
        augmented[row][j] -= factor * augmented[column][j];
      }
    }
  }

  return List.generate(count, (index) => augmented[index][count]);
}

bool isConvexQuad(List<Offset> points) {
  if (points.length != 4) return false;
  var direction = 0;
  for (var i = 0; i < 4; i++) {
    final a = points[i];
    final b = points[(i + 1) % 4];
    final c = points[(i + 2) % 4];
    final ab = b - a;
    final bc = c - b;
    final cross = ab.dx * bc.dy - ab.dy * bc.dx;
    if (cross.abs() < 1e-5) continue;
    final sign = cross > 0 ? 1 : -1;
    if (direction != 0 && direction != sign) return false;
    direction = sign;
  }
  return direction != 0;
}

Rect fitPaperRect(Size bounds, double paperAspectRatio, {double fraction = 0.76}) {
  final maxWidth = bounds.width * fraction;
  final maxHeight = bounds.height * fraction;
  var width = maxWidth;
  var height = width / paperAspectRatio;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * paperAspectRatio;
  }
  return Rect.fromCenter(
    center: bounds.center(Offset.zero),
    width: math.max(1, width),
    height: math.max(1, height),
  );
}
