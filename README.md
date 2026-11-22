<p align="center">
  <img src="assets/logo.svg" alt="ForeverOptics Logo" width="140" />
</p>

# ForeverOptics — by jertan

A zero-dependency **World of Warcraft: Forever** (`1.60.1`) addon that exposes and provides full controls for all hidden graphics settings.

## Key Features

- **106 Curated Hidden Graphics Controls** — Organized across 8 tabs covering View Distance & LOD, Grass & Foliage, Lighting/GI/Fog/Shadows, Water & Weather, Particles & Classic Sparkles, Sharpening & Post-FX, Native HDR10 Calibration, and Camera & Engine Performance.
- **Live Client CVar Explorer** — Scans `C_Console.GetAllCommands()` at runtime so every graphics (or engine) CVar in your client is searchable, editable, and resettable, complete with Snapshot & Diff discovery.
- **Presets, 2 Custom Save Slots & Reversibility** — Includes 6 built-in presets (`Performance`, `Balanced`, `Blizzard 10`, `Beyond Ultra`, `Classic Look`, `Handheld / Deck`), **2 custom preset save slots** (`Slot 1` & `Slot 2`), plus 1-click **Undo**, **Pre-Addon Backup**, and per-setting defaults.
- **Built-in Safety & Persistence** — Enforces known crash caps (`waterDetail <= 2`, `reflectionMode <= 3`), queues in-combat edits until combat ends, protects HDR calibration, re-applies your overrides automatically on login, and lets you hide/show the minimap icon anytime.
- **Live FPS & Impact Overlay** — Movable FPS, avg/min, frame-time, and ping display with automatic before/after FPS delta tracking when tweaking settings.

## Slash Commands

| Command | Description |
| --- | --- |
| `/fo` or `/foreveroptics` | Toggle the main ForeverOptics window |
| `/fo explorer` | Open directly to the Live Client CVar Explorer |
| `/fo hdr` | Open directly to the HDR10 & Display Calibration tab |
| `/fo preset <name>` | Apply a preset (`performance`, `balanced`, `blizzard_max`, `beyond_ultra`, `classic_look`, `handheld`) |
| `/fo save <1\|2>` | Save current graphics settings to Custom Slot 1 or 2 |
| `/fo load <1\|2>` | Load saved settings from Custom Slot 1 or 2 |
| `/fo clear <1\|2>` | Clear Custom Slot 1 or 2 |
| `/fo undo` | Undo the last applied preset or slot |
| `/fo apply` | Re-apply all saved CVar overrides immediately |
| `/fo backup` | Restore pre-addon backed-up CVar values |
| `/fo reset` | Reset all managed CVars to Blizzard defaults |
| `/fo fps` | Toggle the movable live FPS & delta overlay |
| `/fo minimap` | Show or hide the minimap icon |
| `/fo restart` | Restart the graphics engine |
| `/fo get <cvar>` | Print a CVar's current value and client default |
| `/fo set <cvar> <value>` | Safely set any CVar (with crash caps & combat queue) |
| `/fo scan [keyword]` | Search live client graphics CVars in chat |
| `/fo snap` / `/fo diff` | Take a CVar snapshot and diff changes |
| `/fo help` | Show all commands in chat |

## License

Copyright (C) 2026 jertan

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.
