import 'package:flutter/material.dart';

import '../game_internals/models/map_grid.dart';
import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';
import 'terrain_cell_visual.dart';

/// Renders the 11×11 map; optional placement preview for [anchorRow]/[anchorCol].
///
/// While [anchorRow]/[anchorCol] are null and a [previewShape] is set, moving the
/// pointer shows a **tentative** preview (web/desktop). The anchor is always the
/// top-left corner of the shape’s bounding box; a dot marks that cell so hollow
/// shapes (e.g. plus) are easier to read.
class MapGridWidget extends StatefulWidget {
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
  State<MapGridWidget> createState() => _MapGridWidgetState();
}

class _MapGridWidgetState extends State<MapGridWidget> {
  int? _hoverR;
  int? _hoverC;

  static int _axisCell(double p, double cellExtent, double gap, int count) {
    var at = 0.0;
    for (var i = 0; i < count; i++) {
      if (p < at + cellExtent) {
        return i;
      }
      at += cellExtent + gap;
    }
    return count - 1;
  }

  void _setHover(int r, int c) {
    if (_hoverR != r || _hoverC != c) {
      setState(() {
        _hoverR = r;
        _hoverC = c;
      });
    }
  }

  void _clearHover() {
    if (_hoverR != null || _hoverC != null) {
      setState(() {
        _hoverR = null;
        _hoverC = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant MapGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lostPreview =
        widget.previewShape == null || widget.previewTerrain == null;
    final anchorSet =
        widget.anchorRow != null && widget.anchorCol != null;
    if (lostPreview || anchorSet) {
      if (_hoverR != null || _hoverC != null) {
        setState(() {
          _hoverR = null;
          _hoverC = null;
        });
      }
    }
  }

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

        final anchorCommitted =
            widget.anchorRow != null && widget.anchorCol != null;
        final effR = anchorCommitted ? widget.anchorRow! : _hoverR;
        final effC = anchorCommitted ? widget.anchorCol! : _hoverC;

        Set<(int, int)>? previewCells;
        var previewOk = false;
        if (widget.previewShape != null &&
            widget.previewTerrain != null &&
            effR != null &&
            effC != null) {
          previewCells =
              widget.previewShape!.placedAt(effR, effC).toSet();
          previewOk = widget.grid
              .canPlace(widget.previewShape!, effR, effC);
        }

        final tentativePreview =
            !anchorCommitted && effR != null && effC != null;

        final trackHover = !widget.readOnly &&
            widget.previewShape != null &&
            widget.previewTerrain != null &&
            !anchorCommitted;

        return MouseRegion(
          onHover: trackHover
              ? (event) {
                  final local = event.localPosition;
                  final r = _axisCell(
                    local.dy,
                    cellExtent,
                    gap,
                    MapGrid.size,
                  );
                  final c = _axisCell(
                    local.dx,
                    cellExtent,
                    gap,
                    MapGrid.size,
                  );
                  _setHover(r, c);
                }
              : null,
          onExit: trackHover ? (_) => _clearHover() : null,
          child: SizedBox(
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
                final t = widget.grid.cellAt(r, c);
                final inPreview =
                    previewCells != null && previewCells.contains((r, c));

                late final TerrainType displayTerrain;
                Color? bgOverride;
                var borderColor = Colors.black26;
                var borderWidth = 0.5;

                if (inPreview && widget.previewTerrain != null) {
                  displayTerrain = widget.previewTerrain!;
                  final fillAlpha = tentativePreview ? 0.5 : 0.85;
                  bgOverride = widget.previewTerrain!.color
                      .withValues(alpha: fillAlpha);
                  borderColor = previewOk
                      ? (tentativePreview
                          ? Colors.green.withValues(alpha: 0.75)
                          : Colors.green)
                      : (tentativePreview
                          ? Colors.red.withValues(alpha: 0.75)
                          : Colors.red);
                  borderWidth = tentativePreview ? 1.5 : 2;
                } else {
                  displayTerrain = t;
                  if (t == TerrainType.empty && widget.grid.isRuins(r, c)) {
                    bgOverride =
                        TerrainType.ruins.color.withValues(alpha: 0.5);
                  }
                }

                final showAnchorBadge = widget.previewShape != null &&
                    effR != null &&
                    effC != null &&
                    r == effR &&
                    c == effC;

                return GestureDetector(
                  onTap: widget.readOnly || widget.onCellTapped == null
                      ? null
                      : () => widget.onCellTapped!(r, c),
                  child: SizedBox(
                    width: cellExtent,
                    height: cellExtent,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        TerrainCellVisual(
                          terrain: displayTerrain,
                          size: cellExtent,
                          backgroundColor: bgOverride,
                          borderColor: borderColor,
                          borderWidth: borderWidth,
                        ),
                        if (showAnchorBadge)
                          Positioned(
                            left: 3,
                            top: 3,
                            child: IgnorePointer(
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 0.75,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 2,
                                      offset: Offset(0, 0.5),
                                      color: Color(0x33000000),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
