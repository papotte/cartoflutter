# Cartographers Flutter Game

## Overview

A Flutter adaptation of _Cartographers: A Roll Player Tale_ built on the Flutter Casual Games Toolkit card template. Each player draws terrain shapes on an 11×11 map grid across 4 seasons, earning reputation stars from scoring cards. Supports single-player and multiplayer (local pass-and-play + online via Firebase).

## Template Baseline

Cloned from `flutter/games/templates/card`. Keeps the existing structure:

- `lib/app_lifecycle`, `audio`, `settings`, `style`, `main_menu`, `win_game`, `player_progress` — minimal changes
- `lib/game_internals/` and `lib/play_session/` — fully replaced with game-specific code
- Dependencies kept: `provider`, `go_router`, `audioplayers`, `shared_preferences`, `logging`
- Added: `firebase_core`, `firebase_auth`, `cloud_firestore`, `uuid`

## Core Data Models (`lib/game_internals/`)

### Terrain & Shapes

- `TerrainType` enum: `empty`, `forest`, `village`, `farm`, `water`, `monster`, `mountain`, `wasteland`, `ruins`
- `TetrominoShape` — immutable list of `(row, col)` offsets from anchor; supports `rotate90()`, `flipH()`, all 8 orientations
- `CardOption` — pairing of `TetrominoShape` + `TerrainType` + `hasCoin` flag

### Cards

- `ExploreCard` — name, `timeValue`, list of `CardOption`s; 13 unique cards + 2 ruins cards, all defined in `lib/data/explore_cards.dart`
- `AmbushCard` — monster `TetrominoShape`, direction (`left`/`right`); 4 cards defined in `lib/data/ambush_cards.dart`
- `ScoringCard` — name, stack (A–D), scoring function `int score(MapGrid grid)` — 16 cards across 4 stacks
- `SeasonCard` — season name, `timeThreshold` (Spring 8, Summer 8, Fall 7, Winter 6), two `ScoringCardSlot` references (A/B, B/C, C/D, D/A)

### Map

- `MapGrid` — 11×11 `TerrainType` matrix + separate boolean masks for `isRuins`, `isMountain`, `isWasteland`
  - `canPlace(shape, row, col) → bool`
  - `place(shape, row, col, terrain)` — mutates grid, notifies listeners
  - `surroundedMountains() → int` — coin track increment
  - `monsterPenalty() → int` — empty spaces adjacent to monster spaces
  - Wilderness (A) and Wastelands (B) initial layouts in `lib/data/map_layouts.dart`

### Game State

- `PlayerState` — name, `MapGrid`, `coinTrack` (filled count), per-season scores `List<SeasonScore>`, total
- `SeasonScore` — scoring card A result, scoring card B result, coin score, monster penalty
- `GameConfig` — player count, player names, map side (A/B), online vs. local, room ID
- `GameState extends ChangeNotifier` — central state machine:
  - `phase`: `explore | draw | check | seasonEnd | gameOver`
  - Current season index (0–3), accumulated time, revealed card stack
  - Explore deck (shuffled explore + 1 ambush card per season)
  - Active scoring cards (4 randomly selected, one per stack)
  - `revealNextCard()`, `confirmPlacement(PlayerState, TetrominoShape, int row, int col)`, `advancePhase()`, `endSeason()`

### Game History

- `PlayerRecord` — player name, final `MapGrid` snapshot (serialized as flat int list), per-season `SeasonScore` list, total stars
- `GameRecord` — unique ID, date/time played, game mode (solo/local/online), map side (A/B), names of active scoring cards, list of `PlayerRecord`s, winner name
- `GameHistoryRepository` — persists and queries `GameRecord`s in Firestore under a `users/{userId}/games` collection; methods: `saveGame(GameRecord)`, `listGames() → Stream<List<GameRecord>>`, `getGame(id) → Future<GameRecord>`, `deleteGame(id)`
  - Called automatically by `GameState.endGame()` — no manual save step for the player
  - Each player in a multiplayer game gets their own `GameRecord` written under their own user document, containing only their map
  - History is available across devices since it lives in Firestore; Firestore offline persistence covers the no-network case

## Scoring Cards (16 total)

Each implemented as a pure function in `lib/game_internals/scoring/`:

- **Stack A (Forest):** Sleepy Valley, Sentinel Wood, Treetower, Greengold Plains
- **Stack B (Village):** Shoreside Expanse, Greenbough, Stoneside Forest, Wildholds
- **Stack C (Farm/Water):** Golden Granary, Canal Lake, The Broken Road, Borderlands
- **Stack D (Special):** Lost Barony, The Cauldrons, Goblin Curse, Shieldgate
  All scoring functions operate only on a completed `MapGrid` snapshot — no side effects.

## Game Loop Logic

1. **Explore Phase:** Reveal top of explore deck. If ruins card → immediately reveal another. If ambush → resolve monster placement (neighbor's map in local/online; automated leftward shift in single-player) and discard.
2. **Draw Phase:** Each player independently selects one `CardOption` and places its shape on their map. In single-player this is just the human player. In local multiplayer, players confirm one at a time on the same device. In online multiplayer, each player draws on their own device simultaneously; a "ready" button submits their placement; the round advances when all players confirm (or a timer expires).
3. **Check Phase:** Sum time values of all revealed cards this season. If ≥ threshold → season end.
4. **Season End:** Score two scoring cards + coins + monster penalty for each player. Prepare next season (reshuffle deck + add new ambush card).
5. **Game End:** After Winter, tally totals. Tiebreak: fewest monster penalty stars total.

## UI Components (`lib/play_session/`)

- `MapGridWidget` — renders 11×11 grid; tappable cells for placement; highlights valid placement area when a shape is selected; shows terrain colors and icons
- `ShapeSelectorWidget` — shows the revealed explore card options; player selects terrain type + shape; shows rotate/flip controls; preview overlay on grid before confirming
- `ExploreCardWidget` — displays the current revealed card with shapes and terrain type icons
- `SeasonTrackerWidget` — top bar showing current season, time bar, edict icons
- `ScorePanel` — collapsible panel showing per-player current season scores and running totals
- `AmbushOverlay` — modal shown when ambush card is revealed, showing which map receives the monster

## Screens

- `MainMenuScreen` (extended from template) — adds Single Player / Local Multiplayer / Online Multiplayer buttons
- `SetupScreen` — player count (1–6), player names, map side A/B, online → generates room code
- `OnlineLobbyScreen` — create/join room, show connected players, start when host is ready
- `PlaySessionScreen` — main game screen, hosts `GameState`, renders map + controls based on current phase
- `SeasonEndScreen` — animates score reveal for all players, shows leaderboard, proceeds to next season
- `GameOverScreen` — final scores, winner announcement; tapping any player's map row navigates to their history detail
- `HistoryScreen` — scrollable list of past `GameRecord`s sorted by date; each row shows date, mode icon, player names, winner, and total stars; accessible from main menu
- `GameHistoryDetailScreen` — shows the full score breakdown for a selected game (per-season scores table, active scoring cards used) plus a tab or swipe-between-players view of each player's final `MapGridWidget` in read-only mode; the map is rendered identically to the in-game view so terrain colours/icons are immediately recognisable

## Multiplayer Architecture

### Local (Pass-and-Play)

- Single `GameState` on device
- Draw phase cycles through each `PlayerState`; device is handed to each player in turn
- Ambush: passed to the next player in list order

### Online (Firebase Firestore)

- `GameRoom` document: `gameConfig`, `gameState` (phase, season, revealed cards, explore deck seed)
- Each player's map is their own sub-document; only they write to it
- Host controls phase transitions (reveal cards, advance season)
- `DrawPhaseSync` subcollection: each player writes their chosen `CardOption` + placement; host reads when all submitted and advances
- `PlayerState` sync uses Firestore real-time listeners → `remoteChanges` stream (already in template's `PlayingArea` pattern)
- Offline resilience: local cache via Firestore offline persistence

## Project Structure

```warp-runnable-command
lib/
├── app_lifecycle/       # unchanged from template
├── audio/               # unchanged
├── settings/            # unchanged
├── style/               # palette extended with terrain colors
├── main_menu/           # extended with mode selection
├── win_game/            # repurposed as game_over/
├── player_progress/     # repurposed for high score tracking
├── data/
│   ├── explore_cards.dart
│   ├── ambush_cards.dart
│   ├── scoring_cards.dart
│   ├── season_cards.dart
│   └── map_layouts.dart
├── game_internals/
│   ├── models/          # TerrainType, TetrominoShape, MapGrid, cards, GameState
│   ├── scoring/         # one file per scoring card
│   └── online/          # Firebase sync layer
├── play_session/
│   ├── play_session_screen.dart
│   ├── map_grid_widget.dart
│   ├── shape_selector_widget.dart
│   ├── explore_card_widget.dart
│   └── season_tracker_widget.dart
├── setup/
├── lobby/
├── season_end/
├── game_over/
├── history/
│   ├── history_screen.dart
│   ├── game_history_detail_screen.dart
│   └── history_map_viewer.dart     # read-only MapGridWidget wrapper
├── main.dart
└── router.dart
```

## Phased Delivery

1. **Phase 1 – Core (single player):** Firebase project setup + anonymous auth, models, map grid UI, shape placement, full game loop for one player, all 16 scoring cards, season progression, game over screen, game history recording and viewer (Firestore-backed from the start).
2. **Phase 2 – Local Multiplayer:** Pass-and-play draw phase, ambush resolution across players, leaderboard; each player on the device writes their own history record under their user ID.
3. **Phase 3 – Online Multiplayer:** Firestore game rooms, room creation/join, synchronized game state, ready system for draw phase; history already works since the infrastructure is in place.

## Key Dependencies to Add

- `firebase_core: ^3.x` + `cloud_firestore: ^5.x` (online multiplayer)
- `uuid: ^4.x` (room codes + game record IDs)
- `collection: ^1.x` (grid algorithms)
- Firebase Auth (anonymous sign-in) — needed to scope history to a user identity across devices
