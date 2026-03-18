import '../game_internals/models/cards.dart';
import '../game_internals/models/tetromino_shape.dart';

/// The four ambush cards included in the game.
final List<AmbushCard> ambushCards = [
  // Gnoll Raid – L-shape attacking from the left
  AmbushCard(
    name: 'Gnoll Raid',
    shape: const TetrominoShape([(0, 0), (1, 0), (2, 0), (2, 1)]),
    direction: AmbushDirection.left,
  ),

  // Bugbear Assault – S-shape attacking from the right
  AmbushCard(
    name: 'Bugbear Assault',
    shape: const TetrominoShape([(0, 1), (0, 2), (1, 0), (1, 1)]),
    direction: AmbushDirection.right,
  ),

  // Kobold Onslaught – T-shape attacking from the left
  AmbushCard(
    name: 'Kobold Onslaught',
    shape: const TetrominoShape([(0, 0), (0, 1), (0, 2), (1, 1)]),
    direction: AmbushDirection.left,
  ),

  // Goblin Attack – Z-shape attacking from the right
  AmbushCard(
    name: 'Goblin Attack',
    shape: const TetrominoShape([(0, 0), (0, 1), (1, 1), (1, 2)]),
    direction: AmbushDirection.right,
  ),
];
