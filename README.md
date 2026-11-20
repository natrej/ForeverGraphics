# Forever Graphics — by jertan

A zero-dependency **World of Warcraft: Forever** (`1.60.1`) addon that exposes and provides full controls for all hidden graphics settings.

## Key Features

- **106 Curated Hidden Graphics Controls** — Organized across 8 tabs covering View Distance & LOD, Grass & Foliage, Lighting/GI/Fog/Shadows, Water & Weather, Particles & Classic Sparkles, Sharpening & Post-FX, Native HDR10 Calibration, and Camera & Engine Performance.
- **Live Client CVar Explorer** — Scans `C_Console.GetAllCommands()` at runtime so every graphics (or engine) CVar in your client is searchable, editable, and resettable, complete with Snapshot & Diff discovery.
- **One-Click Presets & Reversibility** — Includes `Performance`, `Balanced`, `Blizzard 10`, `Beyond Ultra`, `Classic Look`, and `Handheld / Deck` presets, plus 1-click **Undo**, **Pre-Addon Backup**, and per-setting defaults.
- **Built-in Safety & Persistence** — Enforces known crash caps (`waterDetail <= 2`, `reflectionMode <= 3`), queues in-combat edits until combat ends, protects HDR calibration, and re-applies your overrides automatically on login.
- **Live FPS & Impact Overlay** — Movable FPS, avg/min, frame-time, and ping display with automatic before/after FPS delta tracking when tweaking settings.

## Slash Commands

| Command | Description |
| --- | --- |
| `/fg` or `/forevergraphics` | Toggle the main Forever Graphics window |
| `/fg explorer` | Open directly to the Live Client CVar Explorer |
| `/fg hdr` | Open directly to the HDR10 & Display Calibration tab |
| `/fg preset <name>` | Apply a preset (`performance`, `balanced`, `blizzard_max`, `beyond_ultra`, `classic_look`, `handheld`) |
| `/fg undo` | Undo the last applied preset |
| `/fg apply` | Re-apply all saved CVar overrides immediately |
| `/fg backup` | Restore pre-addon backed-up CVar values |
| `/fg reset` | Reset all managed CVars to Blizzard defaults |
| `/fg fps` | Toggle the movable live FPS & delta overlay |
| `/fg minimap` | Show or hide the minimap button |
| `/fg restart` | Restart the graphics engine |
| `/fg get <cvar>` | Print a CVar's current value and client default |
| `/fg set <cvar> <value>` | Safely set any CVar (with crash caps & combat queue) |
| `/fg scan [keyword]` | Search live client graphics CVars in chat |
| `/fg snap` / `/fg diff` | Take a CVar snapshot and diff changes |
| `/fg help` | Show all commands in chat |
