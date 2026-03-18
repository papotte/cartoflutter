import '../models/map_grid.dart';
import '../models/terrain_type.dart';
import 'scoring_helpers.dart';

// ---------------------------------------------------------------------------
// Stack A (Forest-themed in Plan)
// ---------------------------------------------------------------------------

/// 1 star per village orthogonally adjacent to at least one water.
int scoreSleepyValley(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) != TerrainType.village) continue;
      final adjWater = neighbors(
        r,
        c,
      ).any((n) => g.cellAt(n.$1, n.$2) == TerrainType.water);
      if (adjWater) s++;
    }
  }
  return s;
}

/// 1 star per row with exactly one forest.
int scoreSentinelWood(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    int fc = 0;
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) == TerrainType.forest) fc++;
    }
    if (fc == 1) s++;
  }
  return s;
}

/// 3 stars per forest in the largest forest cluster that touches a mountain.
int scoreTreetower(MapGrid g) {
  final clusters = g.clusters(TerrainType.forest);
  int best = 0;
  for (final cl in clusters) {
    final touchesM = cl.any((cell) => touchesMountain(g, cell.$1, cell.$2));
    if (touchesM && cl.length > best) best = cl.length;
  }
  return 3 * best;
}

/// 3 stars per forest not orthogonally adjacent to another forest.
int scoreGreengoldPlains(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) != TerrainType.forest) continue;
      final lone = !neighbors(
        r,
        c,
      ).any((n) => g.cellAt(n.$1, n.$2) == TerrainType.forest);
      if (lone) s += 3;
    }
  }
  return s;
}

// ---------------------------------------------------------------------------
// Stack B (Village / mixed)
// ---------------------------------------------------------------------------

/// 1 star per water on the outer edge of the map.
int scoreShoresideExpanse(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) != TerrainType.water) continue;
      if (isEdgeCell(r, c)) s++;
    }
  }
  return s;
}

/// 1 star per forest in the largest forest cluster.
int scoreGreenbough(MapGrid g) {
  final clusters = g.clusters(TerrainType.forest);
  if (clusters.isEmpty) return 0;
  final maxSize = clusters.map((c) => c.length).reduce((a, b) => a > b ? a : b);
  return maxSize;
}

/// 1 star per forest orthogonally adjacent to a mountain.
int scoreStonesideForest(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) != TerrainType.forest) continue;
      if (touchesMountain(g, r, c)) s++;
    }
  }
  return s;
}

/// 1 star per village in the largest village cluster.
int scoreWildholds(MapGrid g) {
  final clusters = g.clusters(TerrainType.village);
  if (clusters.isEmpty) return 0;
  final maxSize = clusters.map((c) => c.length).reduce((a, b) => a > b ? a : b);
  return maxSize;
}

// ---------------------------------------------------------------------------
// Stack C (Farm / water)
// ---------------------------------------------------------------------------

/// 1 star per farm in a farm cluster of size 4+.
int scoreGoldenGranary(MapGrid g) {
  int s = 0;
  for (final cl in g.clusters(TerrainType.farm)) {
    if (cl.length >= 4) s += cl.length;
  }
  return s;
}

/// 1 star per water orthogonally adjacent to a farm.
int scoreCanalLake(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) != TerrainType.water) continue;
      final adjFarm = neighbors(
        r,
        c,
      ).any((n) => g.cellAt(n.$1, n.$2) == TerrainType.farm);
      if (adjFarm) s++;
    }
  }
  return s;
}

/// 1 star per row or column with at least 3 distinct terrain types.
int scoreTheBrokenRoad(MapGrid g) {
  final types = <TerrainType>{
    TerrainType.forest,
    TerrainType.village,
    TerrainType.farm,
    TerrainType.water,
    TerrainType.monster,
    TerrainType.mountain,
    TerrainType.wasteland,
    TerrainType.ruins,
  };

  int rows = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    final seen = <TerrainType>{};
    for (int c = 0; c < MapGrid.size; c++) {
      final t = g.cellAt(r, c);
      if (types.contains(t)) seen.add(t);
    }
    if (seen.length >= 3) rows++;
  }

  int cols = 0;
  for (int c = 0; c < MapGrid.size; c++) {
    final seen = <TerrainType>{};
    for (int r = 0; r < MapGrid.size; r++) {
      final t = g.cellAt(r, c);
      if (types.contains(t)) seen.add(t);
    }
    if (seen.length >= 3) cols++;
  }

  return rows + cols;
}

/// 1 star per filled perimeter cell (forest, village, farm, or water).
int scoreBorderlands(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (!isEdgeCell(r, c)) continue;
      final t = g.cellAt(r, c);
      if (t == TerrainType.forest ||
          t == TerrainType.village ||
          t == TerrainType.farm ||
          t == TerrainType.water) {
        s++;
      }
    }
  }
  return s;
}

// ---------------------------------------------------------------------------
// Stack D (Special)
// ---------------------------------------------------------------------------

/// 3 stars per empty space in the second-largest empty region.
int scoreLostBarony(MapGrid g) {
  final regions = emptyRegions(g);
  if (regions.length < 2) return 0;
  final sizes = regions.map((r) => r.length).toList()..sort();
  final secondLargest = sizes[sizes.length - 2];
  return 3 * secondLargest;
}

/// 1 star per water orthogonally adjacent to a mountain.
int scoreTheCauldrons(MapGrid g) {
  int s = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) != TerrainType.water) continue;
      if (touchesMountain(g, r, c)) s++;
    }
  }
  return s;
}

/// Lose 1 star per empty space adjacent to a monster (edict penalty).
int scoreGoblinCurse(MapGrid g) {
  return -g.monsterPenalty();
}

/// Greater of: rows with exactly one village, or columns with exactly one village.
int scoreShieldgate(MapGrid g) {
  int rowCount = 0;
  for (int r = 0; r < MapGrid.size; r++) {
    int vc = 0;
    for (int c = 0; c < MapGrid.size; c++) {
      if (g.cellAt(r, c) == TerrainType.village) vc++;
    }
    if (vc == 1) rowCount++;
  }
  int colCount = 0;
  for (int c = 0; c < MapGrid.size; c++) {
    int vc = 0;
    for (int r = 0; r < MapGrid.size; r++) {
      if (g.cellAt(r, c) == TerrainType.village) vc++;
    }
    if (vc == 1) colCount++;
  }
  return rowCount > colCount ? rowCount : colCount;
}
