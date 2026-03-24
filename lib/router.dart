// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'game_internals/models/player_state.dart';
import 'main_menu/cards_reference_screen.dart';
import 'main_menu/main_menu_screen.dart';
import 'play_session/play_session_screen.dart';
import 'settings/settings_screen.dart';
import 'style/my_transition.dart';
import 'style/palette.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(key: Key('main menu')),
      routes: [
        GoRoute(
          path: 'play',
          pageBuilder: (context, state) {
            final cfg = state.extra as GameConfig?;
            return buildMyTransition<void>(
              key: const ValueKey('play'),
              color: context.watch<Palette>().backgroundPlaySession,
              child: PlaySessionScreen(
                key: const Key('play session'),
                config: cfg,
              ),
            );
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) =>
              const SettingsScreen(key: Key('settings')),
        ),
        GoRoute(
          path: 'cards',
          builder: (context, state) =>
              const CardsReferenceScreen(key: Key('cards reference')),
        ),
      ],
    ),
  ],
);
