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
  }

  void _pickOption(CardOption o) {
    setState(() {
      _selShape = o.shape;
      _selTerrain = o.terrain;
      _anchorR = null;
      _anchorC = null;
    });
  }

  void _onCellTap(int r, int c) {
    if (_selShape == null || _selTerrain == null) return;
    setState(() {
      _anchorR = r;
      _anchorC = c;
    });
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

  Widget _buildExploreOption(BuildContext context, CardOption o) {
    final selected = _selShape == o.shape && _selTerrain == o.terrain;
    final scheme = Theme.of(context).colorScheme;
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PolyominoShapeWidget(shape: o.shape, fillTerrain: o.terrain),
              const SizedBox(height: 8),
              Text(
                '${o.terrain.displayName} (${o.shape.cells.length})'
                '${o.hasCoin ? " 🪙" : ""}',
                style: Theme.of(context).textTheme.labelLarge,
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
            const Card(
              color: Colors.amberAccent,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('Place on a ruins space if you can.'),
              ),
            ),
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in card.options) _buildExploreOption(context, o),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: MapGridWidget(
              grid: p.map,
              previewShape: _selShape,
              previewTerrain: _selTerrain,
              anchorRow: _anchorR,
              anchorCol: _anchorC,
              onCellTapped: _onCellTap,
            ),
          ),
          const SizedBox(height: 12),
          if (_anchorR != null &&
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
