import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/ambush_cards.dart';
import '../../data/explore_cards.dart';
import '../../data/map_layouts.dart';
import '../../data/scoring_cards.dart';
import 'cards.dart';
import 'map_grid.dart';
import 'player_state.dart';
import 'terrain_type.dart';
import 'tetromino_shape.dart';

// ---------------------------------------------------------------------------
// Deck
// ---------------------------------------------------------------------------

sealed class _DeckEntry {}

class _ExploreEntry extends _DeckEntry {
  _ExploreEntry(this.card);
  final ExploreCard card;
}

class _AmbushEntry extends _DeckEntry {
  _AmbushEntry(this.card);
  final AmbushCard card;
}

// ---------------------------------------------------------------------------

enum GamePhase { explore, draw, check, seasonEnd, gameOver }

class GameState extends ChangeNotifier {
  GameState({required this.config, Random? random})
    : _random = random ?? Random();

  final GameConfig config;
  final Random _random;

  List<PlayerState> players = [];
  late List<ScoringCard> activeScoringCards;

  GamePhase phase = GamePhase.explore;
  int seasonIndex = 0; // 0–3 = Spring–Winter

  /// Time accumulated this season from revealed explore cards.
  int accumulatedTime = 0;

  List<ExploreCard> revealedThisSeason = [];
  List<_DeckEntry> _deck = [];
  int _deckPos = 0;

  /// Card players are placing this draw phase (after any ruins chain).
  ExploreCard? activeExploreCard;

  /// After a Ruins reveal, the next placement must overlap ruins if possible.
  bool mustOverlapRuins = false;

  /// Last ambush message for UI (solo auto-resolve).
  String? lastAmbushMessage;

  void startGame() {
    for (final p in players) {
      p.dispose();
    }
    players = [
      for (final name in config.playerNames)
        PlayerState(
          name: name,
          map: MapGrid.fromLayout(
            mountains: config.useWildernessMap
                ? wildernessMapMountains
                : wastelandsMapMountains,
            ruins: config.useWildernessMap
                ? wildernessMapRuins
                : wastelandsMapRuins,
            wastelands: config.useWildernessMap
                ? wildernessMapWastelands
                : wastelandsMapWastelands,
          ),
        ),
    ];

    activeScoringCards = [
      scoringCardsStackA[_random.nextInt(scoringCardsStackA.length)],
      scoringCardsStackB[_random.nextInt(scoringCardsStackB.length)],
      scoringCardsStackC[_random.nextInt(scoringCardsStackC.length)],
      scoringCardsStackD[_random.nextInt(scoringCardsStackD.length)],
    ];

    seasonIndex = 0;
    accumulatedTime = 0;
    revealedThisSeason.clear();
    phase = GamePhase.explore;
    _buildSeasonDeck();
    notifyListeners();
  }

  void _buildSeasonDeck() {
    final explore = [...exploreCards, ...ruinsCards]..shuffle(_random);
    final ambush = ambushCards[_random.nextInt(ambushCards.length)];
    final insertAt = _random.nextInt(explore.length + 1);
    _deck = [];
    for (var i = 0; i < explore.length; i++) {
      if (i == insertAt) {
        _deck.add(_AmbushEntry(ambush));
      }
      _deck.add(_ExploreEntry(explore[i]));
    }
    if (insertAt == explore.length) {
      _deck.add(_AmbushEntry(ambush));
    }
    _deckPos = 0;
  }

  Season get currentSeason => Season.values[seasonIndex];

  int get timeThreshold => currentSeason.timeThreshold;

  /// Season time not yet spent ([timeThreshold] minus [accumulatedTime], floored at 0).
  int get remainingSeasonTime {
    final r = timeThreshold - accumulatedTime;
    return r > 0 ? r : 0;
  }

  /// Reveal cards until an explore card starts the draw phase (or deck ends).
  void revealNextCard() {
    if (phase != GamePhase.explore && phase != GamePhase.check) return;
    if (phase == GamePhase.check) {
      phase = GamePhase.explore;
    }

    lastAmbushMessage = null;

    while (_deckPos < _deck.length) {
      final entry = _deck[_deckPos++];

      if (entry is _AmbushEntry) {
        _resolveAmbushSolo(entry.card);
        continue;
      }

      final card = (entry as _ExploreEntry).card;
      if (card.isRuins) {
        mustOverlapRuins = true;
        continue;
      }

      activeExploreCard = card;
      revealedThisSeason.add(card);
      accumulatedTime += card.timeValue;
      phase = GamePhase.draw;
      notifyListeners();
      return;
    }

    _endSeasonForced();
    return;
  }

  void _endSeasonForced() {
    _applySeasonScoring();
    notifyListeners();
  }

  void _resolveAmbushSolo(AmbushCard ambush) {
    if (players.isEmpty) return;
    final map = players.first.map;
    final shape = ambush.shape;
    int? bestR;
    int? bestC;
    for (var r = 0; r < MapGrid.size; r++) {
      for (var c = 0; c < MapGrid.size; c++) {
        if (!map.canPlace(shape, r, c)) continue;
        if (bestC == null || c < bestC || (c == bestC && r < (bestR ?? 0))) {
          bestR = r;
          bestC = c;
        }
      }
    }
    if (bestR != null && bestC != null) {
      map.place(shape, bestR, bestC, TerrainType.monster);
      lastAmbushMessage = '${ambush.name}: monster placed on your map.';
    } else {
      lastAmbushMessage = '${ambush.name}: no valid placement — skipped.';
    }
  }

  /// Validates and applies placement for the active player (solo: index 0).
  void confirmPlacement({
    required int playerIndex,
    required TetrominoShape shape,
    required TerrainType terrain,
    required int row,
    required int col,
  }) {
    if (phase != GamePhase.draw || activeExploreCard == null) {
      throw StateError('Not in draw phase');
    }
    final player = players[playerIndex];
    final map = player.map;

    if (mustOverlapRuins && map.canPlaceOnRuins(shape)) {
      final placed = shape.placedAt(row, col);
      final onRuins = placed.any((cell) => map.isRuins(cell.$1, cell.$2));
      if (!onRuins) {
        throw StateError('Must place overlapping a ruins space');
      }
    }

    if (!map.canPlace(shape, row, col)) {
      throw StateError('Illegal placement');
    }

    if (activeExploreCard!.isRiftLands) {
      if (shape.cells.length != 1) {
        throw StateError('Rift Lands uses 1×1 only');
      }
      if (!terrain.isPlayerPlaceable && terrain != TerrainType.monster) {
        throw StateError('Invalid Rift terrain');
      }
    }

    CardOption? matchingOpt;
    for (final o in activeExploreCard!.options) {
      if (o.shape == shape && o.terrain == terrain) {
        matchingOpt = o;
        break;
      }
    }
    if (matchingOpt == null) {
      throw StateError('Shape/terrain not on current card');
    }

    final coinsFromMountains = map.place(shape, row, col, terrain);
    player.addCoins(coinsFromMountains);

    if (matchingOpt.hasCoin) {
      player.addCoins(1);
    }

    mustOverlapRuins = false;
    _afterDrawPhase();
  }

  void _afterDrawPhase() {
    phase = GamePhase.check;
    activeExploreCard = null;

    if (accumulatedTime >= timeThreshold) {
      _applySeasonScoring();
    } else {
      phase = GamePhase.explore;
    }
    notifyListeners();
  }

  void _applySeasonScoring() {
    phase = GamePhase.seasonEnd;
    final season = currentSeason;
    final (stack1, stack2) = season.scoringStacks;
    final card1 = activeScoringCards.firstWhere((c) => c.stack == stack1);
    final card2 = activeScoringCards.firstWhere((c) => c.stack == stack2);

    for (final p in players) {
      final g = p.map;
      final s1 = card1.score(g);
      final s2 = card2.score(g);
      final coinStars = p.takeCoinStarsAndReset();
      final mp = g.monsterPenalty();
      p.recordSeasonScore(
        SeasonScore(
          season: season,
          scoringCard1Stars: s1,
          scoringCard2Stars: s2,
          coinStars: coinStars,
          monsterPenalty: mp,
        ),
      );
    }
  }

  /// Call after season end UI — advance to next season or game over.
  void acknowledgeSeasonEnd() {
    if (phase != GamePhase.seasonEnd) return;

    if (seasonIndex >= 3) {
      phase = GamePhase.gameOver;
      notifyListeners();
      return;
    }

    seasonIndex++;
    accumulatedTime = 0;
    revealedThisSeason.clear();
    activeExploreCard = null;
    mustOverlapRuins = false;
    _buildSeasonDeck();
    phase = GamePhase.explore;
    notifyListeners();
  }

  /// Build a record after [phase] is [GamePhase.gameOver].
  GameRecord buildCompletedGameRecord(String id) {
    return GameRecord(
      id: id,
      playedAt: DateTime.now(),
      mode: config.mode,
      usedWildernessMap: config.useWildernessMap,
      activeScoringCardNames: activeScoringCards.map((c) => c.name).toList(),
      players: players.map(PlayerRecord.fromPlayerState).toList(),
      winnerName: winner.name,
    );
  }

  /// Tiebreak: fewest total monster penalty stars.
  List<PlayerState> leadersByScore() {
    if (players.isEmpty) return [];
    var best = players.first.totalStars;
    for (final p in players) {
      if (p.totalStars > best) best = p.totalStars;
    }
    final top = players.where((p) => p.totalStars == best).toList();
    if (top.length == 1) return top;
    top.sort((a, b) => a.totalMonsterPenalty.compareTo(b.totalMonsterPenalty));
    final fewest = top.first.totalMonsterPenalty;
    return top.where((p) => p.totalMonsterPenalty == fewest).toList();
  }

  PlayerState get winner => leadersByScore().first;

  @override
  void dispose() {
    for (final p in players) {
      p.dispose();
    }
    super.dispose();
  }
}
