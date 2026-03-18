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
        return const Color(0xFFF5ECD7);
      case TerrainType.forest:
        return const Color(0xFF2D7D46);
      case TerrainType.village:
        return const Color(0xFFE07B39);
      case TerrainType.farm:
        return const Color(0xFFE8D44D);
      case TerrainType.water:
        return const Color(0xFF4A90D9);
      case TerrainType.monster:
        return const Color(0xFF7B2D8B);
      case TerrainType.mountain:
        return const Color(0xFF8B8B8B);
      case TerrainType.wasteland:
        return const Color(0xFF5C4A2A);
      case TerrainType.ruins:
        return const Color(0xFFBCA882);
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
}
