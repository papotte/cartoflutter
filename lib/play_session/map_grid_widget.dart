import 'package:flutter/material.dart';

import '../game_internals/models/map_grid.dart';
import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';

/// Renders the 11×11 map; optional placement preview for [anchorRow]/[anchorCol].
class MapGridWidget extends StatelessWidget {
  const MapGridWidget({
    super.key,
    required this.grid,
    this.previewShape,
    this.previewTerrain,
    this.anchorRow,
    this.anchorCol,
    this.onCellTapped,
    this.readOnly = false,
  });

  final MapGrid grid;
  final TetrominoShape? previewShape;
  final TerrainType? previewTerrain;
  final int? anchorRow;
  final int? anchorCol;
  final void Function(int row, int col)? onCellTapped;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final cell = side / MapGrid.size;

        Set<(int, int)>? previewCells;
        bool previewOk = false;
        if (previewShape != null && anchorRow != null && anchorCol != null) {
          previewCells = previewShape!.placedAt(anchorRow!, anchorCol!).toSet();
          previewOk = grid.canPlace(previewShape!, anchorRow!, anchorCol!);
        }

        return SizedBox(
          width: side,
          height: side,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MapGrid.size,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: MapGrid.size * MapGrid.size,
            itemBuilder: (context, i) {
              final r = i ~/ MapGrid.size;
              final c = i % MapGrid.size;
              final t = grid.cellAt(r, c);
              Color bg = t.color;
              if (t == TerrainType.empty && grid.isRuins(r, c)) {
                bg = TerrainType.ruins.color.withValues(alpha: 0.5);
              }

              Color? border;
              if (previewCells != null && previewCells.contains((r, c))) {
                bg = (previewTerrain ?? t).color.withValues(alpha: 0.85);
                border = previewOk ? Colors.green : Colors.red;
              }

              return GestureDetector(
                onTap: readOnly || onCellTapped == null
                    ? null
                    : () => onCellTapped!(r, c),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(
                      color: border ?? Colors.black26,
                      width: border != null ? 2 : 0.5,
                    ),
                  ),
                  child: Center(child: _iconFor(t, size: cell * 0.45)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget? _iconFor(TerrainType t, {required double size}) {
    IconData? icon;
    switch (t) {
      case TerrainType.forest:
        icon = Icons.park;
        break;
      case TerrainType.village:
        icon = Icons.home;
        break;
      case TerrainType.farm:
        icon = Icons.agriculture;
        break;
      case TerrainType.water:
        icon = Icons.water;
        break;
      case TerrainType.monster:
        icon = Icons.pest_control;
        break;
      case TerrainType.mountain:
        icon = Icons.landscape;
        break;
      case TerrainType.wasteland:
        icon = Icons.texture;
        break;
      case TerrainType.ruins:
        icon = Icons.castle;
        break;
      case TerrainType.empty:
        icon = null;
        break;
    }
    if (icon == null) return null;
    return Icon(icon, size: size, color: Colors.white70);
  }
}
