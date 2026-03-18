import 'package:flutter/foundation.dart';

import 'terrain_type.dart';
import 'tetromino_shape.dart';

/// The 11×11 grid each player draws on throughout the game.
class MapGrid extends ChangeNotifier {
  static const int size = 11;

  /// Current terrain type in each cell.
  late final List<List<TerrainType>> _cells;

  /// Which cells are ruins spaces (pre-printed on the map).
  late final List<List<bool>> _isRuins;

  /// Which cells are mountain spaces (pre-printed, always filled).
  late final List<List<bool>> _isMountain;

  /// Which cells are wasteland spaces (pre-printed, always filled).
  late final List<List<bool>> _isWasteland;

  /// Which ruins spaces have been filled over (for scoring).
  late final List<List<bool>> _isFilledRuins;

  MapGrid._({
    required List<List<TerrainType>> cells,
    required List<List<bool>> isRuins,
    required List<List<bool>> isMountain,
    required List<List<bool>> isWasteland,
  }) : _cells = cells,
       _isRuins = isRuins,
       _isMountain = isMountain,
       _isWasteland = isWasteland,
       _isFilledRuins = List.generate(size, (_) => List.filled(size, false));

  /// Creates a fresh grid from layout booleans.
  factory MapGrid.fromLayout({
    required List<List<bool>> mountains,
    required List<List<bool>> ruins,
    required List<List<bool>> wastelands,
  }) {
    final cells = List.generate(size, (r) {
      return List.generate(size, (c) {
        if (mountains[r][c]) return TerrainType.mountain;
        if (wastelands[r][c]) return TerrainType.wasteland;
        if (ruins[r][c]) return TerrainType.ruins;
        return TerrainType.empty;
      });
    });
    return MapGrid._(
      cells: cells,
      isRuins: ruins,
      isMountain: mountains,
      isWasteland: wastelands,
    );
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  TerrainType cellAt(int row, int col) => _cells[row][col];
  bool isRuins(int row, int col) => _isRuins[row][col];
  bool isMountain(int row, int col) => _isMountain[row][col];
  bool isWasteland(int row, int col) => _isWasteland[row][col];
  bool isFilledRuins(int row, int col) => _isFilledRuins[row][col];

  /// True if a cell is occupied (cannot be drawn on).
  bool isCellFilled(int row, int col) {
    final t = _cells[row][col];
    if (t == TerrainType.mountain || t == TerrainType.wasteland) return true;
    if (t == TerrainType.ruins) return false; // ruins itself is passable
    return t != TerrainType.empty;
  }

  // ---------------------------------------------------------------------------
  // Placement
  // ---------------------------------------------------------------------------

  /// Returns true if [shape] can be placed with its anchor at [row],[col].
  bool canPlace(TetrominoShape shape, int row, int col) {
    for (final cell in shape.placedAt(row, col)) {
      final r = cell.$1;
      final c = cell.$2;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (isCellFilled(r, c)) return false;
    }
    return true;
  }

  /// Returns true if any valid placement of [shape] exists anywhere on the map.
  bool hasAnyValidPlacement(TetrominoShape shape) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }

  /// Returns true if [shape] can be placed overlapping at least one ruins space.
  bool canPlaceOnRuins(TetrominoShape shape) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!canPlace(shape, r, c)) continue;
        final placed = shape.placedAt(r, c);
        if (placed.any((cell) => _isRuins[cell.$1][cell.$2])) return true;
      }
    }
    return false;
  }

  /// Places [shape] anchored at [row],[col] with [terrain], mutating the grid.
  /// Returns the number of newly surrounded mountains (for coin tracking).
  int place(TetrominoShape shape, int row, int col, TerrainType terrain) {
    assert(canPlace(shape, row, col));
    final placed = shape.placedAt(row, col);
    for (final cell in placed) {
      final r = cell.$1;
      final c = cell.$2;
      if (_isRuins[r][c]) _isFilledRuins[r][c] = true;
      _cells[r][c] = terrain;
    }
    final newCoins = _countNewlySurroundedMountains(placed);
    notifyListeners();
    return newCoins;
  }

  // ---------------------------------------------------------------------------
  // Coin / scoring helpers
  // ---------------------------------------------------------------------------

  int _countNewlySurroundedMountains(List<(int, int)> justPlaced) {
    int coins = 0;
    final checked = <(int, int)>{};
    for (final cell in justPlaced) {
      for (final adj in _adjacents(cell.$1, cell.$2)) {
        if (!_isMountain[adj.$1][adj.$2]) continue;
        if (checked.contains(adj)) continue;
        checked.add(adj);
        if (_isMountainSurrounded(adj.$1, adj.$2)) coins++;
      }
    }
    return coins;
  }

  bool _isMountainSurrounded(int r, int c) {
    for (final adj in _adjacents(r, c)) {
      if (!isCellFilled(adj.$1, adj.$2) &&
          _cells[adj.$1][adj.$2] == TerrainType.empty) {
        return false;
      }
    }
    return true;
  }

  /// Total cells of each [terrain] type (excluding mountains/wastelands).
  int countTerrain(TerrainType terrain) {
    int count = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_cells[r][c] == terrain) count++;
      }
    }
    return count;
  }

  /// Reputation stars lost: one per empty space adjacent to a monster space.
  /// Each empty space only counted once even if adjacent to multiple monsters.
  int monsterPenalty() {
    int penalty = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (_cells[r][c] != TerrainType.empty) continue;
        final adjacentToMonster = _adjacents(
          r,
          c,
        ).any((adj) => _cells[adj.$1][adj.$2] == TerrainType.monster);
        if (adjacentToMonster) penalty++;
      }
    }
    return penalty;
  }

  /// Returns clusters (groups of connected same-terrain cells).
  List<List<(int, int)>> clusters(TerrainType terrain) {
    final visited = List.generate(size, (_) => List.filled(size, false));
    final result = <List<(int, int)>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (visited[r][c] || _cells[r][c] != terrain) continue;
        final cluster = <(int, int)>[];
        final queue = [(r, c)];
        while (queue.isNotEmpty) {
          final cur = queue.removeLast();
          if (visited[cur.$1][cur.$2]) continue;
          visited[cur.$1][cur.$2] = true;
          cluster.add(cur);
          for (final adj in _adjacents(cur.$1, cur.$2)) {
            if (!visited[adj.$1][adj.$2] && _cells[adj.$1][adj.$2] == terrain) {
              queue.add(adj);
            }
          }
        }
        result.add(cluster);
      }
    }
    return result;
  }

  List<(int, int)> _adjacents(int r, int c) {
    final result = <(int, int)>[];
    if (r > 0) result.add((r - 1, c));
    if (r < size - 1) result.add((r + 1, c));
    if (c > 0) result.add((r, c - 1));
    if (c < size - 1) result.add((r, c + 1));
    return result;
  }

  List<(int, int)> adjacentsOf(int r, int c) => _adjacents(r, c);

  // ---------------------------------------------------------------------------
  // Serialization (for Firestore / history)
  // ---------------------------------------------------------------------------

  /// Serializes the terrain grid as a flat list of ints (index in TerrainType.values).
  List<int> toFlatList() {
    return [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) _cells[r][c].index,
    ];
  }

  /// Restores cell terrain from a flat list produced by [toFlatList].
  void fromFlatList(List<int> flat) {
    assert(flat.length == size * size);
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = flat[r * size + c];
        _cells[r][c] = TerrainType.values[val];
        if (_isRuins[r][c] && _cells[r][c] != TerrainType.ruins) {
          _isFilledRuins[r][c] = true;
        }
      }
    }
    notifyListeners();
  }

  /// Deep-copies this grid (used to snapshot for history saving).
  MapGrid snapshot() {
    final copy = MapGrid._(
      cells: List.generate(size, (r) => List<TerrainType>.from(_cells[r])),
      isRuins: List.generate(size, (r) => List<bool>.from(_isRuins[r])),
      isMountain: List.generate(size, (r) => List<bool>.from(_isMountain[r])),
      isWasteland: List.generate(size, (r) => List<bool>.from(_isWasteland[r])),
    );
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        copy._isFilledRuins[r][c] = _isFilledRuins[r][c];
      }
    }
    return copy;
  }
}
