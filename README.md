# Forever Graphics — World of Warcraft: Forever Addon

**Forever Graphics** is a zero-dependency addon built specifically for **World of Warcraft: Forever** (`1.60.1` / `Interface 16001`) that exposes and provides full interactive controls for **all hidden graphics CVars** — from Beyond Ultra draw distance, lush 256-density grass, shadow cascades, and native HDR10 calibration, to a **Live Client CVar Explorer** that dynamically discovers and controls *every* graphics/engine CVar in the running client via `C_Console.GetAllCommands()`.

## Installation

1. Copy the entire `ForeverGraphics` folder into your World of Warcraft: Forever AddOns directory:
   - **Windows**: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\ForeverGraphics\`
   - **macOS**: `/Applications/World of Warcraft/_forever_/Interface/AddOns/ForeverGraphics/`
   - **Steam Deck / Linux**: `<WoW Install>/_forever_/Interface/AddOns/ForeverGraphics/`
2. Confirm `ForeverGraphics.toc` sits directly inside `Interface/AddOns/ForeverGraphics/`.
3. Launch World of Warcraft: Forever (or type `/reload` in chat) and enable **Forever Graphics** in the AddOns list.

> **Tip:** Back up your `_forever_/WTF/Config.wtf` file before experimenting with extreme graphics CVars. Forever Graphics also automatically backs up every modified CVar's original pre-addon value so you can restore it with one click (`Backup` button or `/fg backup`).

## Key Features

- **106 Curated Hidden Graphics Controls across 8 Categories**:
  1. **World & View** — `farclip` (up to 10,000), `horizonStart`, `horizonClip`, `terrainLodDist`, `TerrainLodDiv`, `terrainLodDoFDistance`, `wmoLodDist`, `wmoDoodadDist`, `entityLodDist`, `doodadLodScale`, `lodObjectCullSize`, `lodObjectCullDist`, `lodObjectMinSize`, `lodObjectFadeScale`, `SkyCloudLOD`, `graphicsViewDistance`.
  2. **Foliage & Ground** — `groundEffectDensity` (up to 256, past menu cap), `groundEffectDist` (up to 600), `groundEffectFade`, `groundEffectAnimation`, `detailDoodadInstancing`, `worldBaseMip`, `terrainMipLevel`.
  3. **Lighting & Shadows** — `giQuality` (Indirect Lighting / Global Illumination), `graphicsLightMode`, `secondaryLighting`, `volumeFog`, `volumeFogLevel`, `sunShafts` (God Rays), `shadowMode`, `shadowTextureSize` (up to 4096), `shadowNumCascades` (4 cascades fixes bright distance fog), `shadowSoft`, `shadowBlendCascades`, `shadowRt`, `entityShadowFadeScale`, `SSAO`, `ssaoType`, `clusteredShading`.
  4. **Water & Weather** — `waterDetail` (safety-capped at 2), `reflectionMode` (safety-capped at 3), `rippleDetail`, `refraction`, `weatherDensity`, `graphicsComputeEffects`, `graphicsDepthEffects`, `projectedTextures`.
  5. **Effects & Details** — `particleDensity`, `particleMTDensity`, `graphicsParticleDensity`, `spellClutter`, `spellVisualDensityFilterSetting`, `physicsLevel`, `bodyQuota`, `ViolenceLevel`, `OutlineEngineMode` (0 = Classic Loot Sparkles), `Outline`, `ObjectSelectionCircle`, `SoftTargetInteract`, `SoftTargetIconGameObject`.
  6. **Image & Post-FX** — `ResampleAlwaysSharpen` (FidelityFX CAS at 100% scale), `ResampleSharpness`, `resampleQuality`, `renderScale`, `DynamicRenderScale`, `DynamicRenderScaleMin`, `ffxAntiAliasingMode`, `MSAAQuality`, `textureFilteringMode`, `ffxGlow` (Bloom), `ffxDeath`, `ffxNether`, `brightness`, `contrast`, `gamma`, `colorblindSimulator`, `colorblindWeaknessFactor`.
  7. **HDR10 & Display** — `HDROutput`, mutually-exclusive `useHDRPeakBrightness` + `HDRPeakBrightness` + `HDRFactor` vs. `useHDRBrightness` + `HDRBrightness`, `renderFormat` (8/10/16-bit), and a live HDR Calibration Status Banner that automatically prevents pitch-black HDR screens.
  8. **Camera & Engine** — `cameraDistanceMaxZoomFactor` (up to 4.0), `cameraZoomSpeed`, `cameraFov`, `cameraSmoothStyle`, `cameraReduceUnexpectedMovement`, `gxVSync`, `gxTripleBuffer`, `gxMaxFrameLatency`, `LowLatencyMode`, `useMaxFPS`/`maxFPS`, `useMaxFPSBk`/`maxFPSBk`, `useTargetFPS`/`targetFPS`, `VRSVal`, and all 6 multithreaded rendering CVars (`gxMTPrepass`, `gxMTBeginDraw`, `gxMTShadow`, `gxMTOpaqueM2`, `gxMTOpaqueWMO`, `gxMTAlphaM2`).
- **Tab 9 — Live Client CVar Explorer**:
  - Dynamically queries `C_Console.GetAllCommands()` at runtime so literally **every** graphics CVar (and optionally every client CVar in the engine) is searchable, inspectable, editable, and resettable.
  - Includes **Snapshot & Diff** so you can snapshot all CVars, change an option in Blizzard's menu, and immediately see every underlying CVar it changed.
- **6 One-Click Presets + Undo + Backup**:
  - `Performance`, `Balanced`, `Blizzard 10`, `Beyond Ultra`, `Classic Look`, and `Handheld / Deck`.
  - Every preset snapshots your prior state for 1-click **Undo**.
- **Built-in WoW: Forever Safety Guards**:
  - Enforces known crash caps (`waterDetail <= 2` to avoid Dalaran crashes; `reflectionMode <= 3` to avoid Ruins of Lordaeron crashes).
  - Combat-lockdown safe: queues changes made in combat and applies them automatically on `PLAYER_REGEN_ENABLED`.
  - Login re-apply & override protection: automatically re-applies your customized CVars after login and protects them against Blizzard's graphics menu silently overwriting them.
  - Client clamp detection: notifies you in chat if Blizzard's client build clamps or locks a CVar value.
- **Live FPS Overlay & Before/After Delta Tracker**:
  - Movable overlay displaying live FPS, 5-second rolling average, 5-second min, frame time (ms), ping, and automatic before/after FPS delta after every CVar adjustment.

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
