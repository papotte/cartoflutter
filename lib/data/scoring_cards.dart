import '../game_internals/models/cards.dart';
import '../game_internals/scoring/scoring_functions.dart';

/// All scoring cards by stack (Plan.md). Pick one random per stack each game.
final List<ScoringCard> scoringCardsStackA = [
  ScoringCard(
    name: 'Sleepy Valley',
    description: '1★ per village adjacent to water.',
    stack: ScoringStack.a,
    scoreFunction: scoreSleepyValley,
  ),
  ScoringCard(
    name: 'Sentinel Wood',
    description: '1★ per row with exactly one forest.',
    stack: ScoringStack.a,
    scoreFunction: scoreSentinelWood,
  ),
  ScoringCard(
    name: 'Treetower',
    description: '3★ per forest in largest forest cluster touching a mountain.',
    stack: ScoringStack.a,
    scoreFunction: scoreTreetower,
  ),
  ScoringCard(
    name: 'Greengold Plains',
    description: '3★ per forest with no adjacent forest.',
    stack: ScoringStack.a,
    scoreFunction: scoreGreengoldPlains,
  ),
];

final List<ScoringCard> scoringCardsStackB = [
  ScoringCard(
    name: 'Shoreside Expanse',
    description: '1★ per water on the map edge.',
    stack: ScoringStack.b,
    scoreFunction: scoreShoresideExpanse,
  ),
  ScoringCard(
    name: 'Greenbough',
    description: '1★ per forest in your largest forest cluster.',
    stack: ScoringStack.b,
    scoreFunction: scoreGreenbough,
  ),
  ScoringCard(
    name: 'Stoneside Forest',
    description: '1★ per forest adjacent to a mountain.',
    stack: ScoringStack.b,
    scoreFunction: scoreStonesideForest,
  ),
  ScoringCard(
    name: 'Wildholds',
    description: '1★ per village in your largest village cluster.',
    stack: ScoringStack.b,
    scoreFunction: scoreWildholds,
  ),
];

final List<ScoringCard> scoringCardsStackC = [
  ScoringCard(
    name: 'Golden Granary',
    description: '1★ per farm in farm clusters of 4+.',
    stack: ScoringStack.c,
    scoreFunction: scoreGoldenGranary,
  ),
  ScoringCard(
    name: 'Canal Lake',
    description: '1★ per water adjacent to a farm.',
    stack: ScoringStack.c,
    scoreFunction: scoreCanalLake,
  ),
  ScoringCard(
    name: 'The Broken Road',
    description: '1★ per row/column with 3+ terrain types.',
    stack: ScoringStack.c,
    scoreFunction: scoreTheBrokenRoad,
  ),
  ScoringCard(
    name: 'Borderlands',
    description: '1★ per forest/village/farm/water on the map edge.',
    stack: ScoringStack.c,
    scoreFunction: scoreBorderlands,
  ),
];

final List<ScoringCard> scoringCardsStackD = [
  ScoringCard(
    name: 'Lost Barony',
    description: '3★ per empty in second-largest empty region.',
    stack: ScoringStack.d,
    scoreFunction: scoreLostBarony,
  ),
  ScoringCard(
    name: 'The Cauldrons',
    description: '1★ per water adjacent to a mountain.',
    stack: ScoringStack.d,
    scoreFunction: scoreTheCauldrons,
  ),
  ScoringCard(
    name: 'Goblin Curse',
    description: '−1★ per empty space adjacent to a monster.',
    stack: ScoringStack.d,
    scoreFunction: scoreGoblinCurse,
  ),
  ScoringCard(
    name: 'Shieldgate',
    description:
        'Rows vs columns with exactly one village — take higher total.',
    stack: ScoringStack.d,
    scoreFunction: scoreShieldgate,
  ),
];

List<List<ScoringCard>> get allScoringStacks => [
  scoringCardsStackA,
  scoringCardsStackB,
  scoringCardsStackC,
  scoringCardsStackD,
];

ScoringCard? cardByStack(List<ScoringCard> active, ScoringStack stack) {
  for (final c in active) {
    if (c.stack == stack) return c;
  }
  return null;
}
