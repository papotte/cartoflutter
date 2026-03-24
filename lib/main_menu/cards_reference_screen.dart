import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ambush_cards.dart';
import '../data/explore_cards.dart';
import '../data/scoring_cards.dart';
import '../game_internals/models/cards.dart';
import '../game_internals/models/terrain_type.dart';
import '../game_internals/models/tetromino_shape.dart';
import '../play_session/polyomino_shape_widget.dart';
import '../style/palette.dart';

const double _kExploreGridGap = 12;
const double _kExploreCardMaxWidth = 320;

/// Rift Lands: one 1×1 legend + wrapped terrain chips (not five horizontal strips).
const double _kRiftReferenceOptionsHeight = 196;

const TetrominoShape _kRiftShapeOne = TetrominoShape([(0, 0)]);

int _exploreColumnCount(double width) {
  if (width >= 960) return 3;
  if (width >= 560) return 2;
  return 1;
}

/// Tile width: full width in single column; capped on multi-column layouts.
double _exploreTileWidth(double maxWidth, int columns) {
  if (columns <= 1) return maxWidth;
  final gaps = _kExploreGridGap * (columns - 1);
  final raw = (maxWidth - gaps) / columns;
  return math.min(raw, _kExploreCardMaxWidth);
}

/// Vertical space for the horizontal option strip (matches [_OptionTile] layout).
double _exploreOptionsStripHeight(ExploreCard card) {
  if (card.options.isEmpty) return 0;
  if (card.isRiftLands) return _kRiftReferenceOptionsHeight;
  const cell = 24.0;
  const polyGap = 2.0;
  var maxRows = 1;
  for (final o in card.options) {
    maxRows = math.max(maxRows, o.shape.height);
  }
  final shapePx = maxRows * cell + (maxRows - 1) * polyGap;
  const optionPadding = 20.0;
  const shapeToLabel = 8.0;
  const labelBlock = 44.0;
  return optionPadding + shapePx + shapeToLabel + labelBlock;
}

/// Outer width for [_OptionTile]: shape grid + padding (avoids horizontal overflow).
double _optionTileOuterWidth(CardOption option, bool compact) {
  final cell = compact ? 18.0 : 26.0;
  const polyGap = 2.0;
  const horizontalPadding = 20.0;
  final cols = option.shape.width;
  final shapeW = cols * cell + (cols - 1) * polyGap;
  final minInner = compact ? 52.0 : 64.0;
  return horizontalPadding + math.max(shapeW, minInner);
}

/// Reference for explore, ambush, and scoring cards, plus a short FAQ.
class CardsReferenceScreen extends StatelessWidget {
  const CardsReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.background4,
      appBar: AppBar(
        title: const Text('Cards & FAQ'),
        backgroundColor: palette.backgroundSettings,
        foregroundColor: palette.inkFullOpacity,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.quiz_outlined,
                title: 'FAQ',
                palette: palette,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FaqTile(
                  question: 'What do explore cards do?',
                  answer:
                      'Each explore card adds its time value to the season timer, then you choose one option: '
                      'a polyomino shape and terrain (and sometimes a coin). Place it on your map if it fits.',
                  palette: palette,
                ),
                _FaqTile(
                  question: 'When does a season end?',
                  answer:
                      'When the season’s time total reaches or passes the threshold shown on the season card '
                      '(after scoring the current explore placement). Then you score the two edicts for that season.',
                  palette: palette,
                ),
                _FaqTile(
                  question: 'How do coins work?',
                  answer:
                      'Some options show a coin. When you take that option, you gain one coin. '
                      'At the end of each season, every three coins on your track become one reputation star (rounded down), then coins reset.',
                  palette: palette,
                ),
                _FaqTile(
                  question: 'What are Ruins?',
                  answer:
                      'Ruins are printed spaces on the map. Temple Ruins and Outpost Ruins are explore-deck cards with '
                      'no shape: when revealed, you immediately reveal the next terrain card and place using that card’s '
                      'options. If any legal placement overlaps at least one ruins square, you must choose such a placement.',
                  palette: palette,
                ),
                _FaqTile(
                  question: 'What is Rift Lands?',
                  answer:
                      'A special explore card with +0 time. You place a single 1×1 cell using any of the terrains shown on the card '
                      '(including monster, if listed).',
                  palette: palette,
                ),
                _FaqTile(
                  question: 'What are ambush cards?',
                  answer:
                      'They force a monster shape onto a map. In this build they are used in the solo flow as shown in play; '
                      'in the board game they target a neighbour’s map.',
                  palette: palette,
                ),
                _FaqTile(
                  question: 'What are scoring / edict cards?',
                  answer:
                      'Four scoring goals are drawn at setup and labeled A–D. Each season scores two of them, as shown on the season card.',
                  palette: palette,
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.explore_outlined,
                title: 'Explore cards',
                palette: palette,
                subtitle: '${exploreCards.length} terrain cards in this build',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _ExploreCardsGrid(
                    maxWidth: constraints.maxWidth,
                    palette: palette,
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.foundation_outlined,
                title: 'Ruins cards',
                palette: palette,
                subtitle:
                    '${ruinsCards.length} modifiers — no shapes; next terrain card supplies the polyomino',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RuinsModifierTile(
                    card: ruinsCards[index],
                    palette: palette,
                  ),
                );
              }, childCount: ruinsCards.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.campaign_outlined,
                title: 'Ambush cards',
                palette: palette,
                subtitle: '${ambushCards.length} monster shapes',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AmbushCardTile(
                    card: ambushCards[index],
                    palette: palette,
                  ),
                );
              }, childCount: ambushCards.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.star_outline,
                title: 'Scoring cards',
                palette: palette,
                subtitle: 'One random card per category each game',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final pool = allScoringCategoryPools[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ScoringCategoryBlock(
                    pool: pool,
                    palette: palette,
                    textTheme: textTheme,
                  ),
                );
              }, childCount: allScoringCategoryPools.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCardsGrid extends StatelessWidget {
  const _ExploreCardsGrid({required this.maxWidth, required this.palette});

  final double maxWidth;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final columns = _exploreColumnCount(maxWidth);
    final tileW = _exploreTileWidth(maxWidth, columns);

    return Align(
      alignment: Alignment.topCenter,
      child: Wrap(
        spacing: _kExploreGridGap,
        runSpacing: _kExploreGridGap,
        alignment: WrapAlignment.center,
        children: [
          for (final c in exploreCards)
            SizedBox(
              width: tileW,
              child: _ExploreCardTile(card: c, palette: palette),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.palette,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final Palette palette;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 26, color: palette.darkPen),
            const SizedBox(width: 10),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: palette.inkFullOpacity,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
        ],
        const SizedBox(height: 8),
        Divider(
          height: 1,
          thickness: 1,
          color: palette.pen.withValues(alpha: 0.15),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.palette,
  });

  final String question;
  final String answer;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.trueWhite,
        elevation: 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.pen.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: EdgeInsets.zero,
            iconColor: palette.darkPen,
            collapsedIconColor: palette.ink,
            title: Text(
              question,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    answer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCardTile extends StatelessWidget {
  const _ExploreCardTile({required this.card, required this.palette});

  final ExploreCard card;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final timeLabel = StringBuffer('+${card.timeValue}');
    if (card.isRiftLands) {
      timeLabel.write(' · Rift');
    }

    return Material(
      color: palette.trueWhite,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: palette.accept.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accept.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: palette.darkPen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel.toString(),
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.inkFullOpacity,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (card.options.isEmpty)
              Text(
                'No placement options.',
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              )
            else if (card.isRiftLands)
              SizedBox(
                height: _kRiftReferenceOptionsHeight,
                child: _RiftLandsReferenceOptions(card: card, palette: palette),
              )
            else
              SizedBox(
                height: _exploreOptionsStripHeight(card),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: card.options.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    return _OptionTile(
                      option: card.options[i],
                      compact: false,
                      palette: palette,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RiftLandsReferenceOptions extends StatelessWidget {
  const _RiftLandsReferenceOptions({required this.card, required this.palette});

  final ExploreCard card;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Always a single 1×1 cell. Choose terrain:',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Center(
          child: PolyominoShapeWidget(
            shape: _kRiftShapeOne,
            fillTerrain: TerrainType.forest,
            cellSize: 26,
            gap: 2,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in card.options)
                  _RiftTerrainChoiceChip(option: o, palette: palette),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RiftTerrainChoiceChip extends StatelessWidget {
  const _RiftTerrainChoiceChip({required this.option, required this.palette});

  final CardOption option;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = option.terrain;
    final icon = t.terrainIcon;

    return SizedBox(
      width: 76,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: BoxDecoration(
          color: palette.backgroundPlaySession.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.pen.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 22, color: t.color)
            else
              const SizedBox(height: 22),
            const SizedBox(height: 4),
            Text(
              t.displayName,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuinsModifierTile extends StatelessWidget {
  const _RuinsModifierTile({required this.card, required this.palette});

  final ExploreCard card;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: palette.trueWhite,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: palette.accept.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accept.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: palette.darkPen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${card.timeValue} · Ruins',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.inkFullOpacity,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No shape on this card. Reveal the next terrain explore card and use its polyomino options as usual. '
              'If a ruins-overlapping placement is legal, you must use one.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.compact,
    required this.palette,
  });

  final CardOption option;
  final bool compact;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cell = compact ? 18.0 : 24.0;

    return Container(
      width: _optionTileOuterWidth(option, compact),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.backgroundPlaySession.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.pen.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PolyominoShapeWidget(
            shape: option.shape,
            fillTerrain: option.terrain,
            cellSize: cell,
            gap: 2,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  option.terrain.displayName,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (option.hasCoin) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.monetization_on_rounded,
                  size: 15,
                  color: palette.accept,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AmbushCardTile extends StatelessWidget {
  const _AmbushCardTile({required this.card, required this.palette});

  final AmbushCard card;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (String entersLabel, IconData entersIcon) = switch (card.direction) {
      AmbushDirection.topLeft => (
        'Monster enters from the top left',
        Icons.south_east_rounded,
      ),
      AmbushDirection.topRight => (
        'Monster enters from the top right',
        Icons.south_west_rounded,
      ),
      AmbushDirection.bottomLeft => (
        'Monster enters from the bottom left',
        Icons.north_east_rounded,
      ),
      AmbushDirection.bottomRight => (
        'Monster enters from the bottom right',
        Icons.north_west_rounded,
      ),
    };

    return Material(
      color: palette.trueWhite,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: palette.redPen.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.redPen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PolyominoShapeWidget(
                shape: card.shape,
                fillTerrain: TerrainType.monster,
                cellSize: 22,
                gap: 2,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(entersIcon, size: 18, color: palette.ink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entersLabel,
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.ink,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoringCategoryBlock extends StatelessWidget {
  const _ScoringCategoryBlock({
    required this.pool,
    required this.palette,
    required this.textTheme,
  });

  final List<ScoringCard> pool;
  final Palette palette;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final category = pool.first.category;
    final accent = _categoryAccent(category, palette);

    return Material(
      color: palette.trueWhite,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.4), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.2)),
              ),
            ),
            child: Text(
              category.displayName,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.inkFullOpacity,
                letterSpacing: 0.2,
              ),
            ),
          ),
          for (var i = 0; i < pool.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: palette.pen.withValues(alpha: 0.08),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pool[i].name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pool[i].description,
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: palette.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _categoryAccent(ScoringCategory c, Palette palette) {
    switch (c) {
      case ScoringCategory.forest:
        return const Color(0xFF355A4A);
      case ScoringCategory.hamlet:
        return palette.accept;
      case ScoringCategory.riverFarmlands:
        return palette.pen;
      case ScoringCategory.arrangement:
        return palette.inkFullOpacity;
    }
  }
}
