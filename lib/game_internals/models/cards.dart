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

enum AmbushDirection { topLeft, topRight, bottomLeft, bottomRight }

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

/// Physical scoring deck on the card back (rulebook): Forest, Hamlet, River &
/// Farmlands, Arrangement. One card is drawn at random from each per game.
enum ScoringCategory { forest, hamlet, riverFarmlands, arrangement }

extension ScoringCategoryExtension on ScoringCategory {
  String get displayName {
    switch (this) {
      case ScoringCategory.forest:
        return 'Forest';
      case ScoringCategory.hamlet:
        return 'Hamlet';
      case ScoringCategory.riverFarmlands:
        return 'River & Farmlands';
      case ScoringCategory.arrangement:
        return 'Arrangement';
    }
  }
}

/// Edict labels A–D placed on the four drawn scoring cards (random assignment
/// each game). Season cards reference which pair of edicts score each season.
enum ScoringStack { a, b, c, d }

extension ScoringStackExtension on ScoringStack {
  String get letter {
    switch (this) {
      case ScoringStack.a:
        return 'A';
      case ScoringStack.b:
        return 'B';
      case ScoringStack.c:
        return 'C';
      case ScoringStack.d:
        return 'D';
    }
  }

  String get edictLabel => 'Edict $letter';
}

/// A scoring card from one of the four category decks, plus a pure scoring
/// function on a completed [MapGrid] snapshot.
@immutable
class ScoringCard {
  final String name;
  final String description;
  final ScoringCategory category;
  final int Function(MapGrid grid) scoreFunction;

  const ScoringCard({
    required this.name,
    required this.description,
    required this.category,
    required this.scoreFunction,
  });

  int score(MapGrid grid) => scoreFunction(grid);
}

/// One active scoring card with its edict slot (A–D) for the current game.
@immutable
class EdictAssignment {
  final ScoringCard card;
  final ScoringStack edict;

  const EdictAssignment({required this.card, required this.edict});
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
