// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.
///
/// The reason we're not going with something like Material Design's
/// `Theme` is simply that this is simpler to work with and yet gives
/// us everything we need for a game.
///
/// Games generally have more radical color palettes than apps. For example,
/// every level of a game can have radically different colors.
/// At the same time, games rarely support dark mode.
///
/// Inspired by: #2274a5, #d9cab3, #bc8034, #463730, #ff101f
///
/// Colors here are implemented as getters so that hot reloading works.
/// In practice, we could just as easily implement the colors
/// as `static const`. But this way the palette is more malleable:
/// we could allow players to customize colors, for example,
/// or even get the colors from the network.
class Palette {
  /// Primary accent (#2274a5).
  Color get pen => const Color(0xff2274a5);

  /// Theme seed — slightly deeper blue for Material contrast.
  Color get darkPen => const Color(0xff1a5c82);

  /// Strong warning / danger (#ff101f).
  Color get redPen => const Color(0xffff101f);

  /// Body text and dark UI (#463730).
  Color get inkFullOpacity => const Color(0xff463730);
  Color get ink => const Color(0xee463730);

  /// Positive / confirm — bronze from the palette (#bc8034).
  Color get accept => const Color(0xffbc8034);

  /// Main menu and theme surface.
  Color get backgroundMain => trueWhite;

  /// Cooler screen — powder blue derived from the primary.
  Color get backgroundLevelSelection => const Color(0xffc5d6e0);

  /// Play / celebration — pale gold from #bc8034 + beige.
  Color get backgroundPlaySession => const Color(0xffe9d9bc);

  /// Alternate light surface.
  Color get background4 => const Color(0xfff2ebe3);

  /// Settings — muted steel blue.
  Color get backgroundSettings => const Color(0xffb8cad6);

  Color get trueWhite => const Color(0xffffffff);
}
