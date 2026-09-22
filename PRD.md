# Product Requirements Document (PRD): Arcade Battle Checkers 👑🕹️

---

## 1. Executive Summary & Vision
**Arcade Battle Checkers** is a fast-paced, high-dopamine reimagining of traditional 8x8 checkers built in **Godot 4**. By combining traditional checkers movement and kinging with **Hero Commander Ultimates**, **Dynamic Power-Up Tiles**, **Fighting-Game Style Combo Multi-Kills**, and **Retro Pixel Visuals**, the game transforms slow turn-based board play into an electric, tactile arcade battle.

---

## 2. Core Game Modes

### ⚔️ Mode A: Arcade Battle Mode (Primary Innovation)
- Includes all Hero Commander selection, Ultimate energy bars, and live Power-Up tile spawns.
- Sub-options:
  - **VS BOT (Arcade)**: Single-player match against automated AI with Hero Ultimate intelligence.
  - **2 PLAYERS (Arcade)**: Local Pass-and-Play match with independent Commander selection.

### ♟️ Mode B: Classic Checkers Mode
- Pure, unadulterated American/English Checkers rules (forced captures, King promotion on back rank).
- Retains juice, screen shake, audio, and visual theme customizations without power-ups or hero abilities.
- Sub-options:
  - **vs Bot (Classic)**
  - **2P Classic**

---

## 3. Game Mechanics & Systems

### 3.1 Standard Rules Engine (`Board.gd`, `Piece.gd`)
- **Grid Layout**: 8x8 board (`TILE_SIZE = 80px`).
- **Initial Setup**: 12 Red pieces (rows 5–7, moving UP) vs 12 Black pieces (rows 0–2, moving DOWN) on alternating dark tiles (`(x+y)%2 != 0`).
- **Standard Movement**: 1-step forward diagonal movement.
- **Captures (Jumps)**: Diagonal jump over an opponent piece onto an empty landing tile. Mandatory jump priority is enforced if any jump is available.
- **Multi-Jumps**: Chained consecutive jumps in a single turn.
- **King Promotion**: Reaching the opponent's opposite rank crowns the piece with a golden crown, enabling 4-directional diagonal movement and jumping.
- **Victory Conditions**: Eliminating all opponent pieces, or placing the opponent in a state with zero legal moves.

### 3.2 Dynamic Power-Up Tiles (`PowerUpManager.gd`)
Every 3 turns during Arcade Mode, mystery power-up orbs spawn on unoccupied neutral dark tiles (max 4 concurrent on board):
1. **💣 Bomb Orb**: Explodes in an 8-direction radius upon landing, eliminating adjacent enemy pieces.
2. **🌀 Warp Portal**: Spawns in pairs. Stepping into one instantly teleports the piece to the linked exit portal across the board.
3. **🛡️ Energy Shield**: Surrounds the piece in an energy forcefield that absorbs 1 capture/death without destroying the piece.
4. **⚡ Lightning Dash**: Overcharges the piece with 4-directional omni-movement and extended movement range for 1 turn.

### 3.3 Hero Commanders & Ultimate Abilities (`HeroManager.gd`)
Players choose their Commander before match start. Making moves (+15%), captures (+35%), and combos (+60%) fills the 0–100% **Ultimate Meter**:
1. **🔥 Pyromancer** (*Ultimate: METEOR STRIKE*): Targets and immediately destroys any selected enemy checker on the board from the sky.
2. **⚡ Void Rogue** (*Ultimate: SHADOW SWAP*): Selects an enemy checker and instantly swaps its board coordinate with a friendly checker.
3. **🛡️ Titan Knight** (*Ultimate: IRON WALL*): Instantly grants Energy Shields to 2 random friendly checkers.

### 3.4 Fighting Game Combo Counter & Flame Streak (`ComboBanner.gd`)
- **Combo Banners**: Pulling off multi-jumps in sequence triggers screen-slamming arcade banners:
  - `2x COMBO!` (Gold)
  - `3x MEGA COMBO!!` (Blazing Orange)
  - `4x ULTRA COMBO!!!` (Neon Pink)
- **On-Fire State**: A piece scoring 2+ kills in a turn ignites into rising flame particles, glowing magma skin, and blazing ghost trails for **2.0 seconds**.

### 3.5 AI Difficulty Tiers (`BotAI.gd`)
1. **EASY**: Picks random legal moves, greedily executing jumps when available.
2. **MEDIUM**: Evaluates board material, center-board control, forward advancement, and king preservation.
3. **HARD (MINIMAX)**: Lookahead engine that projects opponent counter-jumps and protects vulnerable flanks.

---

## 4. Visual Style, Vibe & Aesthetic

### 4.1 Pixel Art & Typography
- **Font**: Google *Press Start 2P* (`PixelFont.ttf`) arcade font across all UI, headers, and buttons.
- **Piece Aesthetics**: Chunky stepped pixel outlines, glint highlights, and stepped pixel crown jewels.
- **Motion Blur / Ghosting**: High-speed movement leaves a soft 4-stage color-matched ghost trail ribbon behind moving pieces.

### 4.2 4 Dynamic Visual Themes (`ThemeManager.gd`)
1. **Classic Pixel**: Warm birch cream & navy slate board with pixel borders.
2. **Cyberpunk Neon**: High-contrast dark void with neon magenta (`#FF0D8C`) and electric cyan (`#00D9F2`).
3. **Retro Wood**: Vintage mahogany and golden pine timber board.
4. **Magma Inferno**: Charred volcanic obsidian tiles with fiery orange magma checkers.

---

## 5. Viewport, Resolution & Cross-Platform Architecture

### 5.1 Project Viewport Settings (`project.godot`)
- **Base Resolution**: `720 x 1280` (Standard 9:16 mobile portrait).
- **Stretch Mode**: `canvas_items` with `aspect = "expand"`.
- **Touch Emulation**: `emulate_touch_from_mouse = true` & `emulate_mouse_from_touch = true`.
- **Texture Filtering**: Nearest-Neighbor (`default_texture_filter = 0`) for crisp pixel preservation.
- **Texture Compression**: `import_etc2_astc = true` (enables Apple Silicon & Android ARM64 exports).

### 5.2 Layout Breakdown
- **Desktop & Mobile Unified**:
  - **Top Bar**: Game title, active mode badge, AI difficulty toggle, and score indicator (`R: 12 | B: 12`).
  - **Center Zone**: Centered 8x8 checkerboard (`640x640px` area) with large touch/click targets.
  - **Bottom Deck (Thumb Zone)**: Hero Commander avatar, Ultimate charge bar, glowing `ULTIMATE READY` button, theme cycle, restart, menu buttons, and audio toggles.

---

## 6. Audio Architecture (`AudioManager.gd`)
- **Soundtrack**: Loops `res://Audio/nastelbom-soundtrack-443631.mp3` at `-8.0 dB`.
- **Procedurally Synthesized SFX**:
  - `play_select()`: High-frequency blip.
  - `play_move()`: Sliding wood tactile tone.
  - `play_capture()`: Sub-bass thud + crunch burst with dynamic pitch shift (`±4%`).
  - `play_combo()`: Dual-tone fighting game impact.
  - `play_fire_ignite()`: Flame whoosh power surge.
  - `play_powerup()`: Arpeggiated pickup jingle.
  - `play_bomb()`: Heavy low-frequency detonation.
  - `play_portal()`: Sine-frequency warp sound.
  - `play_shield_absorb()`: Metallic barrier deflection.
  - `play_king()`: A-Major fanfare.
  - `play_win()`: Celebratory victory jingle.

---

## 7. Project File Structure
```
godot-checkers/
├── project.godot               # Engine, viewport (720x1280), touch & mobile settings
├── export_presets.cfg          # macOS (.dmg) & Android (.apk) export definitions
├── debug.keystore              # Android signing keystore
├── icon.svg                    # Vector app icon
├── Audio/
│   └── nastelbom-soundtrack-443631.mp3
├── fonts/
│   └── PixelFont.ttf           # Google Press Start 2P arcade font
├── scenes/
│   ├── Main.tscn               # Master orchestrator assembling camera, board, UI, and menus
│   ├── Board.tscn              # 8x8 grid rendering, selection, and collision
│   ├── Piece.tscn              # Piece rendering, motion ghosts, shields & king crowns
│   ├── UI.tscn                 # Mobile top bar and bottom deck HUD
│   ├── Menu.tscn               # Title menu with Arcade Battle and Classic modes
│   ├── HeroSelect.tscn         # Hero Commander selection screen
│   └── ComboBanner.tscn        # Animated fighting-game combo hit notification
└── scripts/
    ├── Main.gd                 # State machine coordinating scenes, signals & camera shake
    ├── Board.gd                # Checkers rules engine, multi-jumps, powerups & ultimates
    ├── Piece.gd                # Piece animations, fire state, shields & ghost trails
    ├── BotAI.gd                # Easy / Medium / Hard Minimax AI lookahead
    ├── HeroManager.gd          # Commander stats, ultimate charge & ability data
    ├── PowerUpManager.gd       # Spawning & tracking Bomb, Portal, Shield & Lightning orbs
    ├── ThemeManager.gd         # 4 color palettes and theme dispatcher
    ├── AudioManager.gd         # Soundtrack playback and procedural SFX synthesis
    ├── GameCamera.gd           # Camera screen shake controller
    ├── CaptureExplosion.gd     # Particle bursts and shockwave rings
    ├── UI.gd                   # HUD event handling and ultimate button controls
    ├── Menu.gd                 # Main menu event dispatcher
    └── HeroSelect.gd           # Character pick event dispatcher
```

---

## 8. Export Targets & Binaries Built
- **macOS**: `Checkers.dmg` (Ad-hoc signed Universal Apple Silicon / Intel DMG).
- **Android**: `Checkers.apk` (Signed ARM64/v7a APK ready for Google Drive / Sideloading).
- **Repository**: [https://github.com/sylasjr/arcade-battle-checkers](https://github.com/sylasjr/arcade-battle-checkers)
