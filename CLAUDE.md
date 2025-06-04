# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Japanese bullet hell vertical shooting game originally implemented as HTML/JavaScript and converted to Godot 4.4. The game features a player ship that can move and shoot in multiple directions, various enemy types with different movement patterns, and a progression system that unlocks more firing patterns as the score increases.

## Architecture

**Godot Project Structure**:
- **Project Configuration**: `project.godot` - Godot 4.4 project with 480x640 fixed resolution
- **Scene Files**: Modular scene architecture with Main, Player, Enemy, Bullet, and DestroyEffect scenes
- **Script Files**: GDScript implementation for game logic and behavior (including SoundManager)
- **Asset Management**: SVG icon and procedural asset generation (no external image/sound files)

**Core Game Systems**:
- **Player System** (`scripts/Player.gd`): Area2D-based movement with precise 1-pixel radius collision detection, progressive multi-directional firing, visual hitbox indicator
- **Enemy System** (`scripts/Enemy.gd`): 6 enemy types with color-coded health/score, 2-color pixel art patterns, 4 movement behaviors, and 16-direction bullet patterns
- **Bullet Systems** (`scripts/Bullet.gd`): Position-based movement (no physics), automatic cleanup on screen boundaries
- **Bomb System** (`scripts/GameManager.gd`): Emergency clear ability consuming 1 life, removes all enemies and enemy bullets with white flash effect
- **Game Management** (`scripts/GameManager.gd`): Central game state, scoring, collision detection using Area2D overlap detection, camera shake effects
- **UI Management** (`scripts/UIManager.gd`): Score display, life counter, difficulty indicator, start/game over screens with flash effects, stage progress bar
- **Sound System** (`scripts/SoundManager.gd`): Procedurally generated sound effects using AudioStreamWAV
- **Effect System** (`scripts/DestroyEffect.gd`): Particle effects and score popups for enemy destruction
- **High Score System** (`scripts/HighScoreManager.gd`): Persistent local storage of top 10 scores with visual ranking
- **Stage System** (`scripts/StageManager.gd`): 5-stage progression with themed backgrounds and enemy patterns

**Key Technical Features**:
- **Custom Pixel Art Rendering**: All sprites drawn via `_draw()` functions using 8x8 pattern arrays
- **Non-Physics Movement**: Direct position manipulation to avoid physics-based collisions and bouncing
- **Precise Collision Detection**: Area2D overlap detection for bullets, enemies, and player
- **Score-Based Progression**: Unlocks additional firing patterns at 1000, 3000, 6000 points (3→5→7→9 directions)
- **Dynamic Difficulty**: Enemy spawn rate increases with score (up to 0.09 max rate) × stage multiplier
- **Bomb System**: Strategic life-consuming clear ability with visual flash effects and cooldown prevention
- **Visual Feedback**: Hitbox indicators, particle effects, screen shake, flash effects
- **Audio System**: Procedurally generated sounds with proper mixing and overlap prevention
- **Persistent Data**: High score saving/loading using Godot's user:// directory
- **Stage Progression**: 5 unique stages with color-coded themes and enemy patterns

## Development Environment

This project requires Godot 4.4+ for optimal compatibility. The main entry point is `scenes/Main.tscn`.

**Key Godot Features Used**:
- Area2D nodes for collision detection without physics interference
- Custom _draw() functions for pixel art rendering with 2-color support
- Signal system for event communication between game objects
- CanvasLayer for UI management with responsive layouts

**Important Implementation Details**:
- **Collision System**: Uses Area2D overlap detection instead of physics to prevent bouncing
- **Movement System**: Direct position manipulation for smooth, predictable movement
- **Pixel Art System**: 8x8 pattern arrays with support for 2-color sprites (enemy ships)
- **Collision Radii**: Player (1px), Enemy (12px), Bullet (4px) for balanced gameplay
- **Camera System**: Camera2D at screen center (240, 320) for proper viewport alignment and shake effects
- **Sound Generation**: Uses AudioStreamWAV with programmatically generated waveforms
- **Performance**: Object pooling preparation, cleanup optimization, efficient collision checks

**Controls**:
- Arrow keys or WASD: Move player ship
- Spacebar: Shoot (continuous fire while held)
- Z key: Bomb (consumes 1 life, clears screen)
- Click "Start Game" to begin
- Click "High Scores" to view rankings
- Click "Restart" after game over
- Click "View High Scores" after game over to see if you made the top 10

**Running the Project**:
1. Open in Godot 4.4+
2. Set `scenes/Main.tscn` as the main scene in project settings
3. Run the project (F5)