# Repository visuals

`hero.gif` and its static alternative `hero.png` combine the existing Vedomax 3D animation, bundled Roboto fonts and the app palette. They are generated locally with `python scripts/create_readme_art.py` (Pillow required). No new character artwork or external images are introduced.

README screenshots link directly to reviewed Flutter render snapshots in `test/goldens`. Refresh them through the widget tests after a visual UI change. The GIF has 60 frames at 20 fps; the README picture element supplies the static poster for reduced-motion browsers.
