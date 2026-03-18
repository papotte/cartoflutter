# App icon

- **`app_icon.svg`** — full launcher art (parchment + map). Quill/ink marks use paths adapted from a feather-pen style SVG (same transform stack as SVGRepo-style sources). Edit this as the source of truth.
- **`app_icon_adaptive_foreground.svg`** — same artwork without the base fill, for Android adaptive icons (background is `#F4E8C8` in `pubspec.yaml`).

After changing the SVGs, regenerate PNGs and platform assets:

```bash
rsvg-convert -w 1024 -h 1024 assets/icons/app_icon.svg -o assets/icons/icon.png
rsvg-convert -w 1024 -h 1024 assets/icons/app_icon_adaptive_foreground.svg -o assets/icons/icon-adaptive-foreground.png
flutter pub run flutter_launcher_icons
```

Use **`flutter pub run …`** (not plain `dart run …`). Standalone Dart does not include the Flutter SDK, so dependency resolution fails for this project.

Requires [librsvg](https://wiki.gnome.org/Projects/LibRsvg) (`brew install librsvg` on macOS).
