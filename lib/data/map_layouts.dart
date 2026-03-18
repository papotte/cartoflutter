/// Map layout data for both sides of the Cartographers map sheet.
///
/// Each layout is an 11×11 boolean grid.
/// Row 0 is the top row, col 0 is the leftmost column.
library;

// Helper to build a blank 11×11 grid
List<List<bool>> _blank() => List.generate(11, (_) => List.filled(11, false));

List<List<bool>> _set(List<List<bool>> grid, List<(int, int)> positions) {
  for (final pos in positions) {
    grid[pos.$1][pos.$2] = true;
  }
  return grid;
}

// ---------------------------------------------------------------------------
// Wilderness (Side A)
// ---------------------------------------------------------------------------

/// Mountain positions on the Wilderness map.
final List<List<bool>> wildernessMapMountains = _set(_blank(), const [
  (0, 5),
  (2, 1),
  (2, 9),
  (4, 3),
  (4, 7),
  (6, 5),
  (8, 2),
  (8, 8),
  (10, 0),
  (10, 10),
]);

/// Ruins positions on the Wilderness map.
final List<List<bool>> wildernessMapRuins = _set(_blank(), const [
  (1, 3),
  (1, 8),
  (3, 5),
  (5, 1),
  (5, 9),
  (7, 4),
  (9, 6),
]);

/// Wasteland positions on the Wilderness map (none on side A).
final List<List<bool>> wildernessMapWastelands = _blank();

// ---------------------------------------------------------------------------
// Wastelands (Side B)
// ---------------------------------------------------------------------------

/// Mountain positions on the Wastelands map (same as Wilderness).
final List<List<bool>> wastelandsMapMountains = _set(_blank(), const [
  (0, 5),
  (2, 1),
  (2, 9),
  (4, 3),
  (4, 7),
  (6, 5),
  (8, 2),
  (8, 8),
  (10, 0),
  (10, 10),
]);

/// Ruins positions on the Wastelands map.
final List<List<bool>> wastelandsMapRuins = _set(_blank(), const [
  (1, 3),
  (1, 8),
  (3, 5),
  (5, 1),
  (5, 9),
  (7, 4),
  (9, 6),
]);

/// Wasteland positions on the Wastelands map (side B has pre-filled cells).
final List<List<bool>> wastelandsMapWastelands = _set(_blank(), const [
  (0, 2),
  (0, 8),
  (3, 0),
  (3, 10),
  (5, 5),
  (7, 0),
  (7, 10),
  (10, 3),
  (10, 7),
]);
