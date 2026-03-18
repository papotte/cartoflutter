import '../models/map_grid.dart';
import '../models/terrain_type.dart';

List<(int, int)> neighbors(int r, int c) {
  final o = <(int, int)>[];
  if (r > 0) o.add((r - 1, c));
  if (r < MapGrid.size - 1) o.add((r + 1, c));
  if (c > 0) o.add((r, c - 1));
  if (c < MapGrid.size - 1) o.add((r, c + 1));
  return o;
}

bool touchesMountain(MapGrid g, int r, int c) {
  for (final n in neighbors(r, c)) {
    if (g.isMountain(n.$1, n.$2)) return true;
  }
  return false;
}

/// Orthogonally connected regions of [TerrainType.empty].
List<List<(int, int)>> emptyRegions(MapGrid g) {
  final visited = List.generate(
    MapGrid.size,
    (_) => List.filled(MapGrid.size, false),
  );
  final result = <List<(int, int)>>[];
  for (int r = 0; r < MapGrid.size; r++) {
    for (int c = 0; c < MapGrid.size; c++) {
      if (visited[r][c] || g.cellAt(r, c) != TerrainType.empty) continue;
      final region = <(int, int)>[];
      final q = <(int, int)>[(r, c)];
      while (q.isNotEmpty) {
        final cur = q.removeLast();
        if (visited[cur.$1][cur.$2]) continue;
        visited[cur.$1][cur.$2] = true;
        region.add(cur);
        for (final n in neighbors(cur.$1, cur.$2)) {
          if (!visited[n.$1][n.$2] &&
              g.cellAt(n.$1, n.$2) == TerrainType.empty) {
            q.add(n);
          }
        }
      }
      result.add(region);
    }
  }
  return result;
}

bool isEdgeCell(int r, int c) {
  return r == 0 || r == MapGrid.size - 1 || c == 0 || c == MapGrid.size - 1;
}
