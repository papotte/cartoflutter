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

// 1×4 horizontal
const _s1x4h = TetrominoShape([(0, 0), (0, 1), (0, 2), (0, 3)]);

// 3×1 vertical
const _s3x1v = TetrominoShape([(0, 0), (1, 0), (2, 0)]);

// Horizontal L (4 cells) — top row of 3, cell below right end
// x x x
//     x
const _sLhoriz = TetrominoShape([(0, 0), (0, 1), (0, 2), (1, 2)]);

const _sLtopright = TetrominoShape([(0, 1), (1, 1), (2, 0), (2, 1)]);

// L tetromino — long leg vertical, short arm to the right of the top cell
// (matches Hinterland Stream card art)
const _sLarmTop = TetrominoShape([(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)]);

// Z shape
const _sZshape = TetrominoShape([(0, 0), (0, 1), (1, 1), (1, 2)]);

// S-bend (5 cells) — top row pair on the right, bottom row triple on the left
//     x x
// x x x
const _sSbend = TetrominoShape([(0, 2), (0, 3), (1, 0), (1, 1), (1, 2)]);

// T-shape (4 cells)
const _sTshape = TetrominoShape([(0, 0), (0, 1), (0, 2), (1, 1)]);

// Small T (4 cells) — stem on left, middle row extends one cell right
// x
// x x
// x
const _sTsmall = TetrominoShape([(0, 0), (1, 0), (1, 1), (2, 0)]);

// T (5 cells) — stem on left, crossbar on middle row
// x
// x x x
// x
const _sTStemLeft = TetrominoShape([(0, 0), (1, 0), (1, 1), (1, 2), (2, 0)]);

// Top row 3, bottom row 2 (left-aligned)
const _s3over2 = TetrominoShape([(0, 0), (0, 1), (0, 2), (1, 0), (1, 1)]);

// Cross / plus (only 5-cell fits are legal on board; here used as 2-cell arm)
const _sCross3 = TetrominoShape([(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)]);

// Step (5 cells): top-right single over two over two
//       [ ]
//   [ ][ ]
// [ ][ ]
const _sStep = TetrominoShape([(0, 2), (1, 1), (1, 2), (2, 0), (2, 1)]);

// 3-cell L
const _sSmallL = TetrominoShape([(0, 0), (1, 0), (1, 1)]);

// Forgotten Forest + coin (2 cells)
// x
//   x
const _s2off = TetrominoShape([(0, 0), (1, 1)]);

// Forgotten Forest no coin (4 cells)
// x
// x x
//  x
const _s4hook = TetrominoShape([(0, 0), (1, 0), (1, 1), (2, 1)]);

// ---------------------------------------------------------------------------
// Explore cards
// ---------------------------------------------------------------------------

/// Terrain explore cards (shuffled with [ruinsCards] into the season deck).
final List<ExploreCard> exploreCards = [
  // 1. Farmland — plus vs vertical 2 + coin; +1 time
  // Checked and completed.
  ExploreCard(
    name: 'Farmland',
    timeValue: 1,
    options: [
      CardOption(shape: _sCross3, terrain: TerrainType.farm),
      CardOption(shape: _s2x1v, terrain: TerrainType.farm, hasCoin: true),
    ],
  ),

  // 2. Hinterland Stream — same L as farm or water; +2 time
  // Checked and completed.
  ExploreCard(
    name: 'Hinterland Stream',
    timeValue: 2,
    options: [
      CardOption(shape: _sLarmTop, terrain: TerrainType.farm),
      CardOption(shape: _sLarmTop, terrain: TerrainType.water),
    ],
  ),

  // 3. Fishing Village — same 1×4; water or village; +2 time
  // Checked and completed.
  ExploreCard(
    name: 'Fishing Village',
    timeValue: 2,
    options: [
      CardOption(shape: _s1x4h, terrain: TerrainType.water),
      CardOption(shape: _s1x4h, terrain: TerrainType.village),
    ],
  ),

  // 4. Hamlet — 3-L + coin vs 3-over-2; +1 time; village
  // Checked and completed.
  ExploreCard(
    name: 'Hamlet',
    timeValue: 1,
    options: [
      CardOption(shape: _sSmallL, terrain: TerrainType.village, hasCoin: true),
      CardOption(shape: _s3over2, terrain: TerrainType.village),
    ],
  ),

  // 5. Forgotten Forest — 2-cell offset + coin vs 4-cell hook; +1 time
  // Checked and completed.
  ExploreCard(
    name: 'Forgotten Forest',
    timeValue: 1,
    options: [
      CardOption(shape: _s2off, terrain: TerrainType.forest, hasCoin: true),
      CardOption(shape: _s4hook, terrain: TerrainType.forest),
    ],
  ),

  // 6. Great River — stepped 5 vs 3 vertical + coin; +1 time
  ExploreCard(
    name: 'Great River',
    timeValue: 1,
    options: [
      CardOption(shape: _sStep, terrain: TerrainType.water),
      CardOption(shape: _s3x1v, terrain: TerrainType.water, hasCoin: true),
    ],
  ),

  // 7. Homestead — same small T; village or farm; +2 time
  // Checked and completed.
  ExploreCard(
    name: 'Homestead',
    timeValue: 2,
    options: [
      CardOption(shape: _sTsmall, terrain: TerrainType.village),
      CardOption(shape: _sTsmall, terrain: TerrainType.farm),
    ],
  ),

  // 8. Marshlands — same T for water or forest; +2 time
  // Checked and completed.
  ExploreCard(
    name: 'Marshlands',
    timeValue: 2,
    options: [
      CardOption(shape: _sTStemLeft, terrain: TerrainType.water),
      CardOption(shape: _sTStemLeft, terrain: TerrainType.forest),
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

  // 11. Treetop Village — same S-bend; forest or village; +2 time
  ExploreCard(
    name: 'Treetop Village',
    timeValue: 2,
    options: [
      CardOption(shape: _sSbend, terrain: TerrainType.forest),
      CardOption(shape: _sSbend, terrain: TerrainType.village),
    ],
  ),

  // 12. Clearing
  ExploreCard(
    name: 'Clearing',
    timeValue: 2,
    options: [
      CardOption(shape: _sZshape, terrain: TerrainType.forest),
      CardOption(shape: _s1x2h, terrain: TerrainType.village, hasCoin: true),
    ],
  ),

  // 13. Orchard — same horizontal L; forest or farm; +2 time
  // Checked and completed.
  ExploreCard(
    name: 'Orchard',
    timeValue: 2,
    options: [
      CardOption(shape: _sLhoriz, terrain: TerrainType.forest),
      CardOption(shape: _sLhoriz, terrain: TerrainType.farm),
    ],
  ),

  // 14. Rift Lands (special – each player draws a 1×1 of any shown terrain)
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

/// Ruins modifiers: no shapes; the next revealed terrain card supplies the shape and options.
/// Shuffled into the season deck with [exploreCards].
final List<ExploreCard> ruinsCards = [
  ExploreCard(
    name: 'Temple Ruins',
    timeValue: 0,
    options: [],
    type: ExploreCardType.ruins,
  ),
  ExploreCard(
    name: 'Outpost Ruins',
    timeValue: 0,
    options: [],
    type: ExploreCardType.ruins,
  ),
];
