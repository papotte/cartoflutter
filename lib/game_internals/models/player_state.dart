import 'package:flutter/foundation.dart';

import 'cards.dart';
import 'map_grid.dart';

// ---------------------------------------------------------------------------
// SeasonScore
// ---------------------------------------------------------------------------

/// Scores earned by a player at the end of one season.
@immutable
class SeasonScore {
  final Season season;
  final int scoringCard1Stars;
  final int scoringCard2Stars;
  final int coinStars;
  final int monsterPenalty;

  const SeasonScore({
    required this.season,
    required this.scoringCard1Stars,
    required this.scoringCard2Stars,
    required this.coinStars,
    required this.monsterPenalty,
  });

  int get total =>
      scoringCard1Stars + scoringCard2Stars + coinStars - monsterPenalty;

  Map<String, dynamic> toJson() => {
    'season': season.index,
    'scoringCard1Stars': scoringCard1Stars,
    'scoringCard2Stars': scoringCard2Stars,
    'coinStars': coinStars,
    'monsterPenalty': monsterPenalty,
  };

  factory SeasonScore.fromJson(Map<String, dynamic> json) => SeasonScore(
    season: Season.values[json['season'] as int],
    scoringCard1Stars: json['scoringCard1Stars'] as int,
    scoringCard2Stars: json['scoringCard2Stars'] as int,
    coinStars: json['coinStars'] as int,
    monsterPenalty: json['monsterPenalty'] as int,
  );
}

// ---------------------------------------------------------------------------
// PlayerState
// ---------------------------------------------------------------------------

/// All mutable state for one player during a live game session.
class PlayerState extends ChangeNotifier {
  final String name;
  final MapGrid map;

  int _coinTrack = 0;
  final List<SeasonScore> seasonScores = [];

  PlayerState({required this.name, required this.map});

  int get coinTrack => _coinTrack;

  int get totalStars => seasonScores.fold(0, (sum, s) => sum + s.total);

  int get totalMonsterPenalty =>
      seasonScores.fold(0, (sum, s) => sum + s.monsterPenalty);

  void addCoins(int count) {
    _coinTrack += count;
    notifyListeners();
  }

  /// Stars from coins this season (1★ per 3 coins), then reset track.
  int takeCoinStarsAndReset() {
    final stars = _coinTrack ~/ 3;
    _coinTrack = 0;
    notifyListeners();
    return stars;
  }

  void recordSeasonScore(SeasonScore score) {
    seasonScores.add(score);
    notifyListeners();
  }

  @override
  void dispose() {
    map.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// GameConfig
// ---------------------------------------------------------------------------

enum GameMode { solo, localMultiplayer, onlineMultiplayer }

class GameConfig {
  final List<String> playerNames;
  final bool useWildernessMap; // true = side A, false = side B (wastelands)
  final GameMode mode;
  final String? roomId; // online multiplayer only

  const GameConfig({
    required this.playerNames,
    this.useWildernessMap = true,
    this.mode = GameMode.solo,
    this.roomId,
  });

  int get playerCount => playerNames.length;
}

// ---------------------------------------------------------------------------
// PlayerRecord / GameRecord  (history)
// ---------------------------------------------------------------------------

/// Snapshot of one player's result, stored in Firestore history.
class PlayerRecord {
  final String name;
  final List<int> mapFlat; // 121-element flat terrain list
  final List<SeasonScore> seasonScores;
  final int totalStars;
  final int totalMonsterPenalty;

  PlayerRecord({
    required this.name,
    required this.mapFlat,
    required this.seasonScores,
    required this.totalStars,
    required this.totalMonsterPenalty,
  });

  factory PlayerRecord.fromPlayerState(PlayerState ps) {
    return PlayerRecord(
      name: ps.name,
      mapFlat: ps.map.toFlatList(),
      seasonScores: List.unmodifiable(ps.seasonScores),
      totalStars: ps.totalStars,
      totalMonsterPenalty: ps.totalMonsterPenalty,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'mapFlat': mapFlat,
    'seasonScores': seasonScores.map((s) => s.toJson()).toList(),
    'totalStars': totalStars,
    'totalMonsterPenalty': totalMonsterPenalty,
  };

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
    name: json['name'] as String,
    mapFlat: List<int>.from(json['mapFlat'] as List),
    seasonScores: (json['seasonScores'] as List)
        .map((s) => SeasonScore.fromJson(s as Map<String, dynamic>))
        .toList(),
    totalStars: json['totalStars'] as int,
    totalMonsterPenalty: json['totalMonsterPenalty'] as int,
  );
}

/// A completed game record stored in Firestore.
class GameRecord {
  final String id;
  final DateTime playedAt;
  final GameMode mode;
  final bool usedWildernessMap;

  /// Four strings like `A: Sentinel Wood` (edict letter + card name).
  final List<String> activeScoringCardNames;
  final List<PlayerRecord> players;
  final String winnerName;

  GameRecord({
    required this.id,
    required this.playedAt,
    required this.mode,
    required this.usedWildernessMap,
    required this.activeScoringCardNames,
    required this.players,
    required this.winnerName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'playedAt': playedAt.toIso8601String(),
    'mode': mode.index,
    'usedWildernessMap': usedWildernessMap,
    'activeScoringCardNames': activeScoringCardNames,
    'players': players.map((p) => p.toJson()).toList(),
    'winnerName': winnerName,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    id: json['id'] as String,
    playedAt: DateTime.parse(json['playedAt'] as String),
    mode: GameMode.values[json['mode'] as int],
    usedWildernessMap: json['usedWildernessMap'] as bool,
    activeScoringCardNames: List<String>.from(
      json['activeScoringCardNames'] as List,
    ),
    players: (json['players'] as List)
        .map((p) => PlayerRecord.fromJson(p as Map<String, dynamic>))
        .toList(),
    winnerName: json['winnerName'] as String,
  );
}
