import 'package:flutter/foundation.dart';

/// An immutable polyomino shape, represented as a list of (row, col) offsets
/// from the top-left bounding corner of the shape.
@immutable
class TetrominoShape {
  final List<(int, int)> cells;

  const TetrominoShape(this.cells);

  /// Returns a new shape rotated 90° clockwise.
  TetrominoShape rotate90() {
    // (r, c) → (c, -r); then re-normalize to top-left origin
    final rotated = cells.map((cell) => (cell.$2, -cell.$1)).toList();
    return _normalize(rotated);
  }

  /// Returns a new shape flipped horizontally (mirrored along vertical axis).
  TetrominoShape flipH() {
    final flipped = cells.map((cell) => (cell.$1, -cell.$2)).toList();
    return _normalize(flipped);
  }

  /// Returns all unique orientations of this shape (up to 8: 4 rotations × 2 flips).
  List<TetrominoShape> allOrientations() {
    final seen = <String>{};
    final result = <TetrominoShape>[];
    TetrominoShape current = this;
    for (int flip = 0; flip < 2; flip++) {
      for (int rot = 0; rot < 4; rot++) {
        final key = current._key;
        if (seen.add(key)) {
          result.add(current);
        }
        current = current.rotate90();
      }
      current = current.flipH();
    }
    return result;
  }

  /// Width of the bounding box.
  int get width {
    if (cells.isEmpty) return 0;
    final cols = cells.map((c) => c.$2);
    return cols.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Height of the bounding box.
  int get height {
    if (cells.isEmpty) return 0;
    final rows = cells.map((c) => c.$1);
    return rows.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Translates this shape so that all cells land at [anchorRow], [anchorCol].
  List<(int, int)> placedAt(int anchorRow, int anchorCol) {
    return cells.map((c) => (c.$1 + anchorRow, c.$2 + anchorCol)).toList();
  }

  String get _key => (List<(int, int)>.from(
    cells,
  )..sort(_cellComparator)).map((c) => '${c.$1},${c.$2}').join(';');

  static int _cellComparator((int, int) a, (int, int) b) {
    final rowCmp = a.$1.compareTo(b.$1);
    return rowCmp != 0 ? rowCmp : a.$2.compareTo(b.$2);
  }

  static TetrominoShape _normalize(List<(int, int)> cells) {
    if (cells.isEmpty) return TetrominoShape(const []);
    final minRow = cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minCol = cells.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    final normalized = cells
        .map((c) => (c.$1 - minRow, c.$2 - minCol))
        .toList();
    normalized.sort(_cellComparator);
    return TetrominoShape(normalized);
  }

  @override
  bool operator ==(Object other) =>
      other is TetrominoShape && other._key == _key;

  @override
  int get hashCode => _key.hashCode;

  @override
  String toString() => 'TetrominoShape($cells)';
}
