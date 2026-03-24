import '../game_internals/models/cards.dart';
import '../game_internals/scoring/scoring_functions.dart';

/// Forest scoring cards (card-back deck).
final List<ScoringCard> scoringForestCards = [
  ScoringCard(
    name: 'Sentinel Wood',
    description: '1★ per row with exactly one forest.',
    category: ScoringCategory.forest,
    scoreFunction: scoreSentinelWood,
  ),
  ScoringCard(
    name: 'Treetower',
    description: '3★ per forest in largest forest cluster touching a mountain.',
    category: ScoringCategory.forest,
    scoreFunction: scoreTreetower,
  ),
  ScoringCard(
    name: 'Greenbough',
    description: '1★ per forest in your largest forest cluster.',
    category: ScoringCategory.forest,
    scoreFunction: scoreGreenbough,
  ),
  ScoringCard(
    name: 'Stoneside Forest',
    description: '1★ per forest adjacent to a mountain.',
    category: ScoringCategory.forest,
    scoreFunction: scoreStonesideForest,
  ),
];

/// Hamlet (village) scoring cards.
final List<ScoringCard> scoringHamletCards = [
  ScoringCard(
    name: 'Wildholds',
    description: '1★ per village in your largest village cluster.',
    category: ScoringCategory.hamlet,
    scoreFunction: scoreWildholds,
  ),
  ScoringCard(
    name: 'Greengold Plains',
    description: '3★ per forest with no adjacent forest.',
    category: ScoringCategory.hamlet,
    scoreFunction: scoreGreengoldPlains,
  ),
  ScoringCard(
    name: 'Shieldgate',
    description:
        'Rows vs columns with exactly one village — take higher total.',
    category: ScoringCategory.hamlet,
    scoreFunction: scoreShieldgate,
  ),
  ScoringCard(
    name: 'Sleepy Valley',
    description: '1★ per village adjacent to water.',
    category: ScoringCategory.hamlet,
    scoreFunction: scoreSleepyValley,
  ),
];

/// River & Farmlands scoring cards.
final List<ScoringCard> scoringRiverFarmlandsCards = [
  ScoringCard(
    name: 'Golden Granary',
    description: '1★ per farm in farm clusters of 4+.',
    category: ScoringCategory.riverFarmlands,
    scoreFunction: scoreGoldenGranary,
  ),
  ScoringCard(
    name: 'Canal Lake',
    description: '1★ per water adjacent to a farm.',
    category: ScoringCategory.riverFarmlands,
    scoreFunction: scoreCanalLake,
  ),
  ScoringCard(
    name: 'Shoreside Expanse',
    description: '1★ per water on the map edge.',
    category: ScoringCategory.riverFarmlands,
    scoreFunction: scoreShoresideExpanse,
  ),
  ScoringCard(
    name: 'The Cauldrons',
    description: '1★ per water adjacent to a mountain.',
    category: ScoringCategory.riverFarmlands,
    scoreFunction: scoreTheCauldrons,
  ),
];

/// Arrangement / map-shape scoring cards (completeness-style goals).
final List<ScoringCard> scoringArrangementCards = [
  ScoringCard(
    name: 'Borderlands',
    description: '1★ per forest/village/farm/water on the map edge.',
    category: ScoringCategory.arrangement,
    scoreFunction: scoreBorderlands,
  ),
  ScoringCard(
    name: 'The Broken Road',
    description: '1★ per row or column with 3+ terrain types.',
    category: ScoringCategory.arrangement,
    scoreFunction: scoreTheBrokenRoad,
  ),
  ScoringCard(
    name: 'Lost Barony',
    description: '3★ per empty in second-largest empty region.',
    category: ScoringCategory.arrangement,
    scoreFunction: scoreLostBarony,
  ),
  ScoringCard(
    name: 'Goblin Curse',
    description: '−1★ per empty space adjacent to a monster.',
    category: ScoringCategory.arrangement,
    scoreFunction: scoreGoblinCurse,
  ),
];

/// All four category decks (setup: draw one random card from each).
List<List<ScoringCard>> get allScoringCategoryPools => [
  scoringForestCards,
  scoringHamletCards,
  scoringRiverFarmlandsCards,
  scoringArrangementCards,
];
