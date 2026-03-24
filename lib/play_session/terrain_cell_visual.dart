import 'package:flutter/material.dart';

import '../game_internals/models/terrain_type.dart';

/// One map or preview cell: terrain fill and optional type icon (shared by
/// [MapGridWidget] and [PolyominoShapeWidget]).
class TerrainCellVisual extends StatelessWidget {
  const TerrainCellVisual({
    super.key,
    required this.terrain,
    required this.size,
    this.backgroundColor,
    this.borderColor = Colors.black26,
    this.borderWidth = 0.5,
    this.borderRadius = BorderRadius.zero,
    this.iconSizeFraction = 0.45,
    this.iconColor = Colors.white70,
  });

  final TerrainType terrain;
  final double size;

  /// When set, used instead of [terrain.color] for the fill.
  final Color? backgroundColor;

  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double iconSizeFraction;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final fill = backgroundColor ?? terrain.color;
    final icon = terrain.terrainIcon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: borderRadius,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: icon == null
            ? null
            : Center(
                child: Icon(
                  icon,
                  size: size * iconSizeFraction,
                  color: iconColor,
                ),
              ),
      ),
    );
  }
}
