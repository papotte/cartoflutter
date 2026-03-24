import 'package:flutter/material.dart';

import '../game_internals/models/map_grid.dart';
import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';
import 'terrain_cell_visual.dart';

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
        const gap = 1.0;
        final cellExtent =
            (side - gap * (MapGrid.size - 1)) / MapGrid.size;

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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MapGrid.size,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemCount: MapGrid.size * MapGrid.size,
            itemBuilder: (context, i) {
              final r = i ~/ MapGrid.size;
              final c = i % MapGrid.size;
              final t = grid.cellAt(r, c);
              final inPreview =
                  previewCells != null && previewCells.contains((r, c));

              late final TerrainType displayTerrain;
              Color? bgOverride;
              var borderColor = Colors.black26;
              var borderWidth = 0.5;

              if (inPreview && previewTerrain != null) {
                displayTerrain = previewTerrain!;
                bgOverride =
                    previewTerrain!.color.withValues(alpha: 0.85);
                borderColor = previewOk ? Colors.green : Colors.red;
                borderWidth = 2;
              } else {
                displayTerrain = t;
                if (t == TerrainType.empty && grid.isRuins(r, c)) {
                  bgOverride =
                      TerrainType.ruins.color.withValues(alpha: 0.5);
                }
              }

              return GestureDetector(
                onTap: readOnly || onCellTapped == null
                    ? null
                    : () => onCellTapped!(r, c),
                child: SizedBox(
                  width: cellExtent,
                  height: cellExtent,
                  child: TerrainCellVisual(
                    terrain: displayTerrain,
                    size: cellExtent,
                    backgroundColor: bgOverride,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
