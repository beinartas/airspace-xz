# airspace-xz

Three-pane live ATC visualizer (`XY` planar map + `XZ` altitude-vs-distance profile + `FL` altitude stack) in a pure OLED amber vacuum-tube aesthetic.

## Features
- **01 / XY**: Full-bleed vector country contours, dotted lat/lon grid, 1-finger pan, 2-finger pinch-to-zoom, mouse-wheel zoom, and 4,571 worldwide airports (`airports.json`)
- **02 / XZ**: Dynamic altitude × distance profile centered on the `XY` map center (`0 NM`), `3° ILS` glide-slope corridor, 90-second projected trajectories, and floating non-overlapping callout labels
- **03 / FL**: Compact altitude-sorted flight strip stack (`HIGH → LOW`)
- Synced selection across all 3 panes with a floating aircraft telemetry window

## Launch
Double-click `launch-xz.bat` (starts a local PowerShell server on `http://localhost:8767/`).
