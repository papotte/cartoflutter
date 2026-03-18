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

    return Scaffold(
      appBar: AppBar(
        title: Text(_game.currentSeason.displayName),
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
            GamePhase.check => const Center(child: CircularProgressIndicator()),
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
            Text(
              'Time ${_game.accumulatedTime} / ${_game.timeThreshold}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
          if (_game.mustOverlapRuins)
            const Card(
              color: Colors.amberAccent,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('Place on a ruins space if you can.'),
              ),
            ),
          Text(
            '${card.name} · +${card.timeValue} time',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in card.options)
                ChoiceChip(
                  label: Text(
                    '${o.terrain.displayName} (${o.shape.cells.length})'
                    '${o.hasCoin ? " 🪙" : ""}',
                  ),
                  selected: _selShape == o.shape && _selTerrain == o.terrain,
                  onSelected: (_) => _pickOption(o),
                ),
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
          Text('Edict A: ${last.scoringCard1Stars} ★'),
          Text('Edict B: ${last.scoringCard2Stars} ★'),
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
