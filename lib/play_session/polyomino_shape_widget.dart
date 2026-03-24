import 'package:flutter/material.dart';

import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';
import 'terrain_cell_visual.dart';

/// Renders a [TetrominoShape] as a tight grid of [TerrainCellVisual] cells.
///
/// Used for explore-card option previews; same cell look as the main board.
class PolyominoShapeWidget extends StatelessWidget {
  const PolyominoShapeWidget({
    super.key,
    required this.shape,
    required this.fillTerrain,
    this.cellSize = 22,
    this.gap = 1,
    this.cellBorderRadius = const BorderRadius.all(Radius.circular(2)),
  });

  final TetrominoShape shape;
  final TerrainType fillTerrain;
  final double cellSize;
  final double gap;
  final BorderRadius cellBorderRadius;

  @override
  Widget build(BuildContext context) {
    if (shape.cells.isEmpty) {
      return SizedBox(width: cellSize, height: cellSize);
    }

    final w = shape.width;
    final h = shape.height;
    final filled = shape.cells.toSet();

    return SizedBox(
      width: w * cellSize + (w - 1) * gap,
      height: h * cellSize + (h - 1) * gap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(h, (r) {
          return Padding(
            padding: EdgeInsets.only(top: r > 0 ? gap : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(w, (c) {
                final isFilled = filled.contains((r, c));
                final t = isFilled ? fillTerrain : TerrainType.empty;
                return Padding(
                  padding: EdgeInsets.only(left: c > 0 ? gap : 0),
                  child: TerrainCellVisual(
                    terrain: t,
                    size: cellSize,
                    borderRadius: cellBorderRadius,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
