import 'package:flutter/foundation.dart';

import 'map_grid.dart';
import 'terrain_type.dart';
import 'tetromino_shape.dart';

// ---------------------------------------------------------------------------
// CardOption
// ---------------------------------------------------------------------------

/// A single drawable option on an explore card: a shape, terrain type, and
/// whether choosing it awards a coin.
@immutable
class CardOption {
  final TetrominoShape shape;
  final TerrainType terrain;
  final bool hasCoin;

  const CardOption({
    required this.shape,
    required this.terrain,
    this.hasCoin = false,
  });
}

// ---------------------------------------------------------------------------
// ExploreCard
// ---------------------------------------------------------------------------

/// The three special explore card types.
enum ExploreCardType { normal, ruins, riftLands }

/// An explore card revealed during the Explore Phase.
@immutable
class ExploreCard {
  final String name;

  /// Time value added to the season timer when this card is revealed.
  final int timeValue;

  final List<CardOption> options;

  final ExploreCardType type;

  const ExploreCard({
    required this.name,
    required this.timeValue,
    required this.options,
    this.type = ExploreCardType.normal,
  });

  bool get isRuins => type == ExploreCardType.ruins;
  bool get isRiftLands => type == ExploreCardType.riftLands;
}

// ---------------------------------------------------------------------------
// AmbushCard
// ---------------------------------------------------------------------------

enum AmbushDirection { left, right }

/// An ambush card that forces monster placement on a neighbour's map.
@immutable
class AmbushCard {
  final String name;
  final TetrominoShape shape;
  final AmbushDirection direction;

  const AmbushCard({
    required this.name,
    required this.shape,
    required this.direction,
  });
}

// ---------------------------------------------------------------------------
// ScoringCard
// ---------------------------------------------------------------------------

enum ScoringStack { a, b, c, d }

/// A scoring card with a name, which stack it belongs to, and a pure scoring
/// function that operates on a completed [MapGrid] snapshot.
@immutable
class ScoringCard {
  final String name;
  final String description;
  final ScoringStack stack;
  final int Function(MapGrid grid) scoreFunction;

  const ScoringCard({
    required this.name,
    required this.description,
    required this.stack,
    required this.scoreFunction,
  });

  int score(MapGrid grid) => scoreFunction(grid);
}

// ---------------------------------------------------------------------------
// SeasonCard
// ---------------------------------------------------------------------------

enum Season { spring, summer, fall, winter }

extension SeasonExtension on Season {
  String get displayName {
    switch (this) {
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.fall:
        return 'Fall';
      case Season.winter:
        return 'Winter';
    }
  }

  int get timeThreshold {
    switch (this) {
      case Season.spring:
        return 8;
      case Season.summer:
        return 8;
      case Season.fall:
        return 7;
      case Season.winter:
        return 6;
    }
  }

  /// The two scoring stacks evaluated at the end of this season.
  (ScoringStack, ScoringStack) get scoringStacks {
    switch (this) {
      case Season.spring:
        return (ScoringStack.a, ScoringStack.b);
      case Season.summer:
        return (ScoringStack.b, ScoringStack.c);
      case Season.fall:
        return (ScoringStack.c, ScoringStack.d);
      case Season.winter:
        return (ScoringStack.d, ScoringStack.a);
    }
  }
}
