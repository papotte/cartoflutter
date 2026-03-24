import 'package:flutter/material.dart';

enum TerrainType {
  empty,
  forest,
  village,
  farm,
  water,
  monster,
  mountain,
  wasteland,
  ruins,
}

extension TerrainTypeExtension on TerrainType {
  String get displayName {
    switch (this) {
      case TerrainType.empty:
        return 'Empty';
      case TerrainType.forest:
        return 'Forest';
      case TerrainType.village:
        return 'Village';
      case TerrainType.farm:
        return 'Farm';
      case TerrainType.water:
        return 'Water';
      case TerrainType.monster:
        return 'Monster';
      case TerrainType.mountain:
        return 'Mountain';
      case TerrainType.wasteland:
        return 'Wasteland';
      case TerrainType.ruins:
        return 'Ruins';
    }
  }

  Color get color {
    switch (this) {
      case TerrainType.empty:
        return const Color(0xFFF2EDE6);
      case TerrainType.forest:
        return const Color(0xFF355A4A);
      case TerrainType.village:
        return const Color(0xFFA72608);
      case TerrainType.farm:
        return const Color(0xFFD4A84A);
      case TerrainType.water:
        return const Color(0xFF2274A5);
      case TerrainType.monster:
        return const Color(0xFF8F3985);
      case TerrainType.mountain:
        return const Color(0xFF7A726B);
      case TerrainType.wasteland:
        return const Color(0xFF6B563E);
      case TerrainType.ruins:
        return const Color(0xFFB5A088);
    }
  }

  /// Whether this terrain counts as a filled space for placement rules.
  bool get isFilled {
    switch (this) {
      case TerrainType.empty:
        return false;
      case TerrainType.ruins:
        return false; // unfilled ruins are NOT filled; filled ruins are tracked separately
      default:
        return true;
    }
  }

  /// Whether this terrain type can be chosen by a player during the draw phase.
  bool get isPlayerPlaceable {
    switch (this) {
      case TerrainType.forest:
      case TerrainType.village:
      case TerrainType.farm:
      case TerrainType.water:
        return true;
      default:
        return false;
    }
  }

  int get index2 {
    return TerrainType.values.indexOf(this);
  }

  /// Icon shown on the map and in shape previews; null for empty cells.
  IconData? get terrainIcon {
    switch (this) {
      case TerrainType.forest:
        return Icons.park;
      case TerrainType.village:
        return Icons.home;
      case TerrainType.farm:
        return Icons.agriculture;
      case TerrainType.water:
        return Icons.water;
      case TerrainType.monster:
        return Icons.pest_control;
      case TerrainType.mountain:
        return Icons.landscape;
      case TerrainType.wasteland:
        return Icons.texture;
      case TerrainType.ruins:
        return Icons.castle;
      case TerrainType.empty:
        return null;
    }
  }
}
