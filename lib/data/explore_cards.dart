import '../game_internals/models/cards.dart';
import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';

// ---------------------------------------------------------------------------
// Common shapes
// ---------------------------------------------------------------------------

// 1×1
const _s1x1 = TetrominoShape([(0, 0)]);

// 1×2 horizontal
const _s1x2h = TetrominoShape([(0, 0), (0, 1)]);

// 2×1 vertical
const _s2x1v = TetrominoShape([(0, 0), (1, 0)]);

// 1×3 horizontal
const _s1x3h = TetrominoShape([(0, 0), (0, 1), (0, 2)]);

// 3×1 vertical
const _s3x1v = TetrominoShape([(0, 0), (1, 0), (2, 0)]);

// 2×2 square
const _s2x2 = TetrominoShape([(0, 0), (0, 1), (1, 0), (1, 1)]);

// L-shape (3 + corner)
const _sLtopleft = TetrominoShape([(0, 0), (1, 0), (2, 0), (2, 1)]);
const _sLtopright = TetrominoShape([(0, 1), (1, 1), (2, 0), (2, 1)]);

// S / Z shapes
const _sSshape = TetrominoShape([(0, 1), (0, 2), (1, 0), (1, 1)]);
const _sZshape = TetrominoShape([(0, 0), (0, 1), (1, 1), (1, 2)]);

// T-shape
const _sTshape = TetrominoShape([(0, 0), (0, 1), (0, 2), (1, 1)]);

// Cross / plus (only 5-cell fits are legal on board; here used as 2-cell arm)
const _sCross3 = TetrominoShape([(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)]);

// Diagonal-adjacent L (4 cells)
const _sLong4 = TetrominoShape([(0, 0), (1, 0), (2, 0), (3, 0)]);

// 3-cell L
const _sSmallL = TetrominoShape([(0, 0), (1, 0), (1, 1)]);

// ---------------------------------------------------------------------------
// Explore cards
// ---------------------------------------------------------------------------

/// The full deck of 13 explore cards.
final List<ExploreCard> exploreCards = [
  // 1. Farmland
  ExploreCard(
    name: 'Farmland',
    timeValue: 1,
    options: [
      CardOption(shape: _s2x2, terrain: TerrainType.farm),
      CardOption(shape: _s1x1, terrain: TerrainType.farm, hasCoin: true),
    ],
  ),

  // 2. Fishing Village
  ExploreCard(
    name: 'Fishing Village',
    timeValue: 2,
    options: [
      CardOption(shape: _sSmallL, terrain: TerrainType.village),
      CardOption(shape: _s1x2h, terrain: TerrainType.water, hasCoin: true),
    ],
  ),

  // 3. Hamlet
  ExploreCard(
    name: 'Hamlet',
    timeValue: 2,
    options: [
      CardOption(shape: _sTshape, terrain: TerrainType.village),
      CardOption(shape: _s1x1, terrain: TerrainType.village, hasCoin: true),
    ],
  ),

  // 4. Forgotten Forest
  ExploreCard(
    name: 'Forgotten Forest',
    timeValue: 2,
    options: [
      CardOption(shape: _sSmallL, terrain: TerrainType.forest),
      CardOption(shape: _s1x1, terrain: TerrainType.forest, hasCoin: true),
    ],
  ),

  // 5. Great River
  ExploreCard(
    name: 'Great River',
    timeValue: 1,
    options: [
      CardOption(shape: _sLong4, terrain: TerrainType.water),
      CardOption(shape: _s1x1, terrain: TerrainType.water, hasCoin: true),
    ],
  ),

  // 6. Homestead
  ExploreCard(
    name: 'Homestead',
    timeValue: 2,
    options: [
      CardOption(shape: _sSmallL, terrain: TerrainType.farm),
      CardOption(shape: _s1x2h, terrain: TerrainType.forest, hasCoin: true),
    ],
  ),

  // 7. Temple Ruins
  ExploreCard(
    name: 'Temple Ruins',
    timeValue: 0,
    options: [
      CardOption(shape: _sSmallL, terrain: TerrainType.farm),
      CardOption(shape: _s1x1, terrain: TerrainType.farm, hasCoin: true),
    ],
  ),

  // 8. Marshlands
  ExploreCard(
    name: 'Marshlands',
    timeValue: 2,
    options: [
      CardOption(shape: _sSshape, terrain: TerrainType.water),
      CardOption(shape: _s2x1v, terrain: TerrainType.forest, hasCoin: true),
    ],
  ),

  // 9. Stone Bridge
  ExploreCard(
    name: 'Stone Bridge',
    timeValue: 2,
    options: [
      CardOption(shape: _sTshape, terrain: TerrainType.village),
      CardOption(shape: _s2x1v, terrain: TerrainType.farm, hasCoin: true),
    ],
  ),

  // 10. Tree of Life
  ExploreCard(
    name: 'Tree of Life',
    timeValue: 2,
    options: [
      CardOption(shape: _sCross3, terrain: TerrainType.forest),
      CardOption(shape: _s1x1, terrain: TerrainType.forest, hasCoin: true),
    ],
  ),

  // 11. Clearing
  ExploreCard(
    name: 'Clearing',
    timeValue: 2,
    options: [
      CardOption(shape: _sZshape, terrain: TerrainType.forest),
      CardOption(shape: _s1x2h, terrain: TerrainType.village, hasCoin: true),
    ],
  ),

  // 12. Orchard
  ExploreCard(
    name: 'Orchard',
    timeValue: 2,
    options: [
      CardOption(shape: _sLtopleft, terrain: TerrainType.farm),
      CardOption(shape: _s1x2h, terrain: TerrainType.forest, hasCoin: true),
    ],
  ),

  // 13. Rift Lands (special – each player draws a 1×1 of any shown terrain)
  ExploreCard(
    name: 'Rift Lands',
    timeValue: 0,
    options: [
      CardOption(shape: _s1x1, terrain: TerrainType.forest),
      CardOption(shape: _s1x1, terrain: TerrainType.village),
      CardOption(shape: _s1x1, terrain: TerrainType.farm),
      CardOption(shape: _s1x1, terrain: TerrainType.water),
      CardOption(shape: _s1x1, terrain: TerrainType.monster),
    ],
    type: ExploreCardType.riftLands,
  ),
];

/// Two ruins cards (added to the explore deck).
final List<ExploreCard> ruinsCards = [
  ExploreCard(
    name: 'Ruins',
    timeValue: 0,
    options: [],
    type: ExploreCardType.ruins,
  ),
  ExploreCard(
    name: 'Ruins',
    timeValue: 0,
    options: [],
    type: ExploreCardType.ruins,
  ),
];
