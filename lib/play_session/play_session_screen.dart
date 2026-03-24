import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../game_internals/history/game_history_repository.dart';
import '../game_internals/models/cards.dart';
import '../game_internals/models/game_state.dart';
import '../game_internals/models/player_state.dart'
    show GameConfig, PlayerState;
import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';
import 'map_grid_widget.dart';
import 'polyomino_shape_widget.dart';

const _kOneCell = TetrominoShape([(0, 0)]);

const List<TerrainType> _kPlayerTerrains = [
  TerrainType.forest,
  TerrainType.village,
  TerrainType.farm,
  TerrainType.water,
];

class PlaySessionScreen extends StatefulWidget {
  const PlaySessionScreen({super.key, this.config});

  final GameConfig? config;

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  late final GameState _game;
  TetrominoShape? _selShape;
  TerrainType? _selTerrain;
  int? _anchorR;
  int? _anchorC;
  bool _saved = false;
  bool _scoringObjectivesExpanded = false;

  /// True after "can't overlap ruins" — player places one 1×1 with [_reliefTerrain].
  bool _ruinsReliefMode = false;
  TerrainType? _reliefTerrain;

  @override
  void initState() {
    super.initState();
    _game = GameState(
      config:
          widget.config ??
          const GameConfig(playerNames: ['You'], useWildernessMap: true),
    );
    _game.startGame();
    _game.addListener(_onGame);
  }

  void _onGame() {
    if (!mounted) return;
    if (_game.phase != GamePhase.draw) {
      _clearSelection();
    }
    if (_game.phase == GamePhase.gameOver && !_saved) {
      _saved = true;
      final record = _game.buildCompletedGameRecord(const Uuid().v4());
      context.read<GameHistoryRepository>().saveGame(record);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _game.removeListener(_onGame);
    _game.dispose();
    super.dispose();
  }

  void _clearSelection() {
    _selShape = null;
    _selTerrain = null;
    _anchorR = null;
    _anchorC = null;
    _ruinsReliefMode = false;
    _reliefTerrain = null;
  }

  void _pickOption(CardOption o) {
    setState(() {
      _selShape = o.shape;
      _selTerrain = o.terrain;
      _anchorR = null;
      _anchorC = null;
      _ruinsReliefMode = false;
      _reliefTerrain = null;
    });
  }

  void _onCellTap(int r, int c) {
    if (_ruinsReliefMode) {
      if (_reliefTerrain == null) return;
      setState(() {
        _anchorR = r;
        _anchorC = c;
      });
      return;
    }
    if (_selShape == null || _selTerrain == null) return;
    setState(() {
      _anchorR = r;
      _anchorC = c;
    });
  }

  void _beginRuinsRelief() {
    if (!_game.mustOverlapRuins || _selShape == null) return;
    final map = _game.players.first.map;
    if (map.canPlaceOnRuins(_selShape!)) return;
    setState(() {
      _ruinsReliefMode = true;
      _reliefTerrain = null;
      _anchorR = null;
      _anchorC = null;
    });
  }

  void _cancelRuinsRelief() {
    setState(() {
      _ruinsReliefMode = false;
      _reliefTerrain = null;
      _anchorR = null;
      _anchorC = null;
    });
  }

  void _confirmRuinsRelief() {
    if (!_ruinsReliefMode ||
        _selShape == null ||
        _reliefTerrain == null ||
        _anchorR == null ||
        _anchorC == null) {
      return;
    }
    try {
      _game.confirmRuinsReliefPlacement(
        playerIndex: 0,
        forfeitedShape: _selShape!,
        terrain: _reliefTerrain!,
        row: _anchorR!,
        col: _anchorC!,
      );
      _clearSelection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _seasonTimeIcon() => const Icon(
    Icons.hourglass_top_outlined,
    size: 22,
    semanticLabel: 'Time remaining',
  );

  Widget _buildScoringObjectivesPanel() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final assignments = _game.activeEdictsSortedByLetter;
    final (e1, e2) = _game.currentSeason.scoringStacks;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _scoringObjectivesExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _scoringObjectivesExpanded = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            'This season scores ${e1.letter} & ${e2.letter}',
            style: textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            for (var i = 0; i < assignments.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildEdictRow(context, assignments[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEdictRow(BuildContext context, EdictAssignment a) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = _game.edictScoresThisSeason(a.edict);
    final borderColor = active
        ? scheme.primary
        : scheme.outline.withValues(alpha: 0.35);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: active ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
        color: active
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  a.edict.edictLabel,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                Text(
                  ' · ${a.card.category.displayName}',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(a.card.name, style: textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              a.card.description,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreOption(
    BuildContext context,
    CardOption o, {
    bool compactRift = false,
  }) {
    final selected = _selShape == o.shape && _selTerrain == o.terrain;
    final scheme = Theme.of(context).colorScheme;
    final cellSize = compactRift ? 20.0 : 22.0;
    final textStyle = compactRift
        ? Theme.of(context).textTheme.labelMedium
        : Theme.of(context).textTheme.labelLarge;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : scheme.outline.withValues(alpha: 0.45),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _pickOption(o),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: compactRift
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PolyominoShapeWidget(
                shape: o.shape,
                fillTerrain: o.terrain,
                cellSize: cellSize,
                gap: 2,
              ),
              SizedBox(height: compactRift ? 6 : 8),
              Text(
                compactRift
                    ? o.terrain.displayName
                    : '${o.terrain.displayName} (${o.shape.cells.length})'
                          '${o.hasCoin ? " 🪙" : ""}',
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmPlacement() {
    if (_selShape == null ||
        _selTerrain == null ||
        _anchorR == null ||
        _anchorC == null) {
      return;
    }
    try {
      _game.confirmPlacement(
        playerIndex: 0,
        shape: _selShape!,
        terrain: _selTerrain!,
        row: _anchorR!,
        col: _anchorC!,
      );
      _clearSelection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _game.players.isNotEmpty ? _game.players.first : null;
    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showSeasonTime = switch (_game.phase) {
      GamePhase.explore || GamePhase.draw || GamePhase.check => true,
      _ => false,
    };

    return Scaffold(
      appBar: AppBar(
        title: showSeasonTime
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_game.currentSeason.displayName),
                  const Text(' · '),
                  _seasonTimeIcon(),
                  const SizedBox(width: 4),
                  Text('${_game.remainingSeasonTime}'),
                ],
              )
            : Text(_game.currentSeason.displayName),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Quit'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_game, p, p.map]),
        builder: (context, _) {
          return switch (_game.phase) {
            GamePhase.explore => _buildExplore(),
            GamePhase.draw => _buildDraw(p),
            GamePhase.check => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScoringObjectivesPanel(),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
            GamePhase.seasonEnd => _buildSeasonEnd(p),
            GamePhase.gameOver => _buildGameOver(),
          };
        },
      ),
    );
  }

  Widget _buildExplore() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScoringObjectivesPanel(),
            if (_game.lastAmbushMessage != null) ...[
              const SizedBox(height: 16),
              Text(_game.lastAmbushMessage!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _game.revealNextCard,
              child: const Text('Reveal card'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraw(PlayerState p) {
    final card = _game.activeExploreCard!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScoringObjectivesPanel(),
          const SizedBox(height: 8),
          if (_game.mustOverlapRuins)
            Card(
              color: Colors.amberAccent,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _ruinsReliefMode
                      ? 'Ruins relief: choose any terrain below, tap one empty square, then confirm. '
                            'This replaces the current card’s shape (no option coin).'
                      : 'Use this card’s shapes and terrains. If any legal placement overlaps a ruins square, you must use one that does.',
                ),
              ),
            ),
          if (_game.mustOverlapRuins && !_ruinsReliefMode) ...[
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton(
                onPressed:
                    _selShape != null && !p.map.canPlaceOnRuins(_selShape!)
                    ? _beginRuinsRelief
                    : null,
                child: const Text('Cannot overlap ruins — place 1×1 instead'),
              ),
            ),
          ],
          if (_game.mustOverlapRuins && _ruinsReliefMode) ...[
            const SizedBox(height: 8),
            Text(
              'Terrain for the single square:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final t in _kPlayerTerrains)
                  ChoiceChip(
                    label: Text(t.displayName),
                    selected: _reliefTerrain == t,
                    onSelected: (_) {
                      setState(() => _reliefTerrain = t);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _cancelRuinsRelief,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed:
                      _anchorR != null &&
                          _anchorC != null &&
                          _reliefTerrain != null
                      ? _confirmRuinsRelief
                      : null,
                  child: const Text('Confirm 1×1'),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 4),
                const Text(' · '),
                _seasonTimeIcon(),
                Text(
                  '+ ${card.timeValue}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: _ruinsReliefMode,
            child: Opacity(
              opacity: _ruinsReliefMode ? 0.45 : 1,
              child: card.isRiftLands
                  ? SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: card.options.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => _buildExploreOption(
                          context,
                          card.options[i],
                          compactRift: true,
                        ),
                      ),
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final o in card.options)
                          _buildExploreOption(context, o),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: MapGridWidget(
              grid: p.map,
              previewShape: _ruinsReliefMode ? _kOneCell : _selShape,
              previewTerrain: _ruinsReliefMode ? _reliefTerrain : _selTerrain,
              anchorRow: _anchorR,
              anchorCol: _anchorC,
              onCellTapped: _onCellTap,
            ),
          ),
          const SizedBox(height: 12),
          if (!_ruinsReliefMode &&
              _anchorR != null &&
              _anchorC != null &&
              _selShape != null &&
              p.map.canPlace(_selShape!, _anchorR!, _anchorC!))
            FilledButton(
              onPressed: _confirmPlacement,
              child: const Text('Confirm placement'),
            ),
        ],
      ),
    );
  }

  Widget _buildSeasonEnd(PlayerState p) {
    final last = p.seasonScores.last;
    final (e1, e2) = last.season.scoringStacks;
    final c1 = _game.cardForEdict(e1);
    final c2 = _game.cardForEdict(e2);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_game.currentSeason.displayName} scores',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '${e1.edictLabel} (${c1?.name ?? "?"}): ${last.scoringCard1Stars} ★',
          ),
          Text(
            '${e2.edictLabel} (${c2?.name ?? "?"}): ${last.scoringCard2Stars} ★',
          ),
          Text('Coins: ${last.coinStars} ★'),
          Text('Monster penalty: −${last.monsterPenalty} ★'),
          const Divider(),
          Text(
            'Season total: ${last.total} ★',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('Game total: ${p.totalStars} ★'),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _game.acknowledgeSeasonEnd,
            child: Text(_game.seasonIndex >= 3 ? 'See results' : 'Next season'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final w = _game.winner;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Game over',
            style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Winner: ${w.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('Total: ${w.totalStars} ★'),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Main menu'),
          ),
        ],
      ),
    );
  }
}
