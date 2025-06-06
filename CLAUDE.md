# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MiniShooting** is a complete, commercial-grade Japanese bullet hell vertical shooting game fully implemented in Godot 4.4. Originally evolved from an HTML/JavaScript prototype, it has achieved professional-level quality with a 5-stage campaign, multi-phase boss battles, sophisticated power-up systems, persistent high score tracking, difficulty selection, and extensive procedural audio/visual effects.

**🎯 Current Status**: **Phase 2+ Complete** - Game logic fully implemented, ready for Phase 3 graphics improvements.

## Architecture

### **Godot Project Structure**
- **Project Configuration**: `project.godot` - Godot 4.4 project, 480x640 fixed resolution, GL compatibility renderer
- **Scene Files**: 8 modular scenes with complete integration (Main, Player, Enemy, Boss, Bullet, PowerUp, DestroyEffect, HighScoreScreen)
- **Script Files**: 13 GDScript files implementing comprehensive game logic across all systems
- **Asset Management**: 100% procedural generation (SVG icon only external asset)

### **Core Game Systems**

#### **Player System** (`scripts/Player.gd`)
- **Precision Movement**: Area2D-based 8-directional movement with 1px accuracy
- **Progressive Firing**: Dynamic 3→18 WAY bullet system
  - **Score-based progression**: 1000/3000/6000 point thresholds (3→5→7→9 WAY)
  - **Power-up enhancement**: P items provide permanent bullet count increases (up to 18 WAY total)
  - **Visual feedback**: Color-coded bullets (Yellow→Cyan/Magenta for effects)
- **Power-up Integration**: 
  - **P (Power)**: Permanent bullet count increase (0-5 levels)
  - **S (Size→Damage)**: 30-second double damage (cyan bullets)
  - **R (Rapid→Piercing)**: 10-second piercing bullets destroy enemy bullets (magenta)
- **Visual Hitbox**: Blue crosshair with red damage flash feedback
- **Metadata Management**: Bullet enhancement via metadata system (piercing, double_damage)

#### **Enemy System** (`scripts/Enemy.gd`)
- **6 Enemy Types**: Color-coded health/scoring system (HP 1-5, scores 10-50)
- **Advanced AI**: 4 movement patterns (straight, sine wave, diagonal, screen-edge return)
- **Combat System**: 16-direction bullet patterns, health-based transparency
- **Retreat System**: Stop shooting and move down at 3x speed when boss is defeated
- **Drop System**: 10% power-up drop rate with weighted type selection (1UP super-rare 1%)
- **Visual Art**: 8x8 pixel art with 2-color gradients for detailed sprites
- **Difficulty Scaling**: HP, speed, and bullet speed multipliers based on difficulty setting

#### **Boss System** (`scripts/Boss.gd`)
- **5 Unique Bosses**: Stage-themed with escalating difficulty (17-300 HP based on difficulty)
- **Multi-phase Combat**: Dynamic attack evolution (8→16→24→32 WAY bullets)
- **Visual Systems**: 32x32 pixel art, real-time health bars with color transitions
- **Rewards**: High-value scoring (1000-5000 points) and stage progression integration
- **Warning System**: "⚠️ WARNING ⚠️ BOSS APPROACHING!" display with red flashing
- **Difficulty Integration**: Boss HP scales from 0.33x (EASY) to 2.0x (LUNATIC)

#### **Difficulty System** (`scripts/SettingsManager.gd`)
- **4 Difficulty Levels**: EASY, NORMAL, HARD, LUNATIC
- **Comprehensive Scaling**: Enemy HP, spawn rate, speed, bullet speed, boss HP
- **Persistent Settings**: Saved to `user://settings.save`
- **Separate High Scores**: Independent TOP10 rankings for each difficulty
- **Balanced Progression**: EASY makes game accessible, LUNATIC provides extreme challenge

#### **Stage System** (`scripts/StageManager.gd`)
- **5-Stage Campaign**: Thematic progression (Green→Blue→Yellow→Red→Purple)
- **Boss Integration**: 100% progress triggers boss spawn, 100% locked until boss defeat
- **Smooth Transitions**: 4-phase system (retreat→clear_display→bg_change→spawn_delay)
- **State Management**: Proper stopping during game over, resume during continue
- **Visual Themes**: Background colors, enemy composition, atmospheric progression
- **No Force Clear**: Boss defeat is mandatory (time limits removed)

#### **Power-Up System** (`scripts/PowerUp.gd`)
- **5 Item Types**: Strategic variety with different mechanics
  - **P (Power)**: Permanent bullet count increase (stacks to level 5)
  - **S (Size→Damage)**: 30-second double damage effect
  - **R (Rapid→Piercing)**: 10-second bullet penetration (destroys enemy bullets)
  - **B (Bomb)**: Instant life +1
  - **1UP**: Super-rare (1%) extra life
- **Visual Design**: 24x24 pixel art with distinct patterns and color coding
- **Mechanics**: Drop rates, automatic cleanup (10s), visual feedback

#### **Bullet Systems** (`scripts/Bullet.gd`)
- **Precision Physics**: Position-based movement without physics engine interference
- **Metadata Support**: Special effects via metadata (piercing, double_damage)
- **Visual Effects**: Color coding for enhanced bullets (cyan for damage, magenta for piercing)
- **Performance**: Automatic cleanup, boundary checking, efficient collision detection

#### **Game Management** (`scripts/GameManager.gd`)
- **Central Coordination**: 12 signal types for decoupled system communication
- **State Management**: Complete control over game/game_over/all_stages_cleared states
- **Collision Detection**: Efficient Area2D overlap detection with metadata processing
- **Performance Optimization**: Object pooling preparation, 60-frame cleanup cycles
- **Power-up Management**: Timer tracking, effect application, visual feedback coordination
- **Stage Integration**: Boss spawning, difficulty scaling, progression management

#### **UI Management** (`scripts/UIManager.gd`)
- **Comprehensive Interface**: Score/lives/stage displays with visual feedback
- **Effect Systems**: Flash effects (white for bomb, red for damage), screen shake
- **Stage Progress**: Large progress bar with color coding and boss warning at 100%
- **High Score Integration**: New record celebrations, ranking displays
- **Message Display**: Centered text with proper sizing (stage clear, boss warning, all clear)
- **Difficulty Integration**: Selection screens and persistent UI state

#### **Sound System** (`scripts/SoundManager.gd`)
- **5 Procedural Sounds**: Complete AudioStreamWAV generation
  - **Shoot**: 2000Hz crisp high-frequency burst (0.1s)
  - **Enemy Destroy**: 150Hz mid-frequency with noise mixing (0.2s)
  - **Player Hit**: 30Hz deep bass pulse (0.5s)
  - **Bomb**: 50Hz ultra-low complex waveform (0.5s)
  - **Power-up**: 400-800Hz ascending harmonic sequence (0.4s)
- **Advanced Features**: Envelope control, frequency modulation, overlap prevention
- **Audio Quality**: Proper mixing at -10dB, waveform synthesis, complex harmonics

#### **High Score System** (`scripts/HighScoreManager.gd`)
- **Difficulty-Separated Storage**: Independent TOP10 for each difficulty level
- **Persistent Storage**: TOP10 scores saved to `user://highscores.save`
- **Ranking Display**: Color-coded ranks (Gold/Silver/Bronze/Cyan) with visual hierarchy
- **Achievement Integration**: New record celebrations, statistical tracking
- **Data Structure**: Date tracking, difficulty-aware, extensible for additional statistics

### **Key Technical Features**

#### **Advanced State Management**
- **Game Over Protection**: Complete stopping of all systems during game over
- **Stage Transition Control**: 4-phase smooth transitions between stages
- **Boss Battle Integration**: 100% progress = boss spawn, locked until defeat
- **Continue System**: Proper state restoration while preserving boss battles

#### **Sophisticated Collision System**
- **Area2D Overlap Detection**: Precise collision without physics engine complications
- **Optimized Radii**: Player (1px), Enemy (12px), Boss (16px), Bullet (4px), PowerUp (15px)
- **Metadata Integration**: Bullet enhancement effects (piercing, double damage) via metadata
- **Performance Optimization**: Early exit conditions, efficient cleanup, batch processing

#### **Signal-Driven Architecture**
```gdscript
# Core 12 signals for decoupled communication
signal score_changed(new_score)
signal lives_changed(new_lives)
signal bomb_used
signal powerup_effect_started(effect_type, duration)
signal powerup_effect_ended(effect_type)
signal enemy_destroyed_effect(position, score_points)
signal stage_info_changed(stage_number, stage_name, progress)
# + 5 additional signals for comprehensive system integration
```

#### **Progressive Difficulty System**
- **Multi-Layered Scaling**: Score-based spawn rates × stage multipliers × difficulty multipliers
- **Boss Health Scaling**: From 0.33x (EASY) to 2.0x (LUNATIC) for accessible→extreme challenge
- **Balanced Progression**: EASY ensures all players can complete, LUNATIC challenges experts
- **Persistent Choice**: Difficulty selection saved and maintained across sessions

#### **Performance Architecture**
- **Object Pooling Framework**: Prepared for high-density bullet patterns (max 50 pooled objects)
- **Efficient Cleanup**: 60-frame cycles for heavy operations, immediate cleanup for critical objects
- **Memory Management**: Proper object lifecycle, avoiding memory leaks, null-safe operations
- **Collision Optimization**: Reverse-order array operations, early termination, efficient overlap detection

### **Development Environment**

**Requirements**:
- **Godot**: 4.4+ (GL Compatibility renderer recommended)
- **Platform**: Windows/Mac/Linux support
- **Resolution**: Fixed 480x640 with aspect ratio maintenance
- **Performance**: 60FPS target across all systems and difficulties

**Key Implementation Patterns**:
- **Modular Design**: Clear separation of responsibilities across 13 script files
- **Signal Communication**: Decoupled systems for maintainability and extensibility
- **Metadata-Driven Effects**: Bullet enhancement system using Godot's metadata
- **Procedural Generation**: 100% code-generated assets for minimal file dependencies
- **Performance-First**: Optimized algorithms prioritizing consistent 60FPS performance

### **Controls & User Experience**

**Input System**:
- **Movement**: WASD/Arrow keys (8-directional, 1px precision)
- **Shooting**: Spacebar (continuous fire, up to 18-WAY with power-ups)
- **Bomb**: Z key (strategic screen clear, life cost, 0.5s cooldown)
- **UI Navigation**: Mouse click for menus and score screens

**User Flow**:
1. **Title Screen**: Start Game (→ Difficulty Selection), High Scores options
2. **Difficulty Selection**: 4 levels with visual indicators and descriptions
3. **5-Stage Campaign**: Progressive difficulty with boss battles (100% = boss)
4. **Game Over**: Restart option, High Score checking (difficulty-aware)
5. **High Score Screen**: Difficulty-separated TOP10 rankings with celebrations

**Accessibility Features**:
- **Visual Hitbox**: Clear player collision indication
- **Color Coding**: Consistent color language across all systems
- **Audio Feedback**: Comprehensive sound design for all actions
- **Progressive Learning**: Natural difficulty curve with 4-level selection
- **Clear Progress**: Meaningful progress bar (100% = boss battle start)

### **Data Architecture**

**Save System**:
- **High Scores**: `user://highscores.save` with difficulty-separated TOP10 persistence
- **Settings**: `user://settings.save` with difficulty preference and options
- **Future Expansion**: Framework ready for achievements and additional features

**Performance Monitoring**:
- **Object Counts**: Real-time tracking of enemies, bullets, effects
- **Cleanup Statistics**: Performance optimization metrics
- **Memory Usage**: Proactive cleanup preventing accumulation

**State Synchronization**:
- **Game States**: Proper coordination between GameManager, StageManager, UI
- **Transition Control**: Smooth state changes with appropriate stopping/starting
- **Error Recovery**: Robust handling of edge cases and state conflicts

## Important Development Guidelines

### **Code Quality Standards**
- **GDScript Best Practices**: Official style guide compliance
- **Signal-First Communication**: Minimize direct object references
- **Null Safety**: Comprehensive `is_instance_valid()` checks
- **Performance Awareness**: 60FPS maintenance across all difficulties
- **Documentation**: Comprehensive commenting for complex algorithms

### **System Integration Principles**
- **Modular Independence**: Each system functions independently
- **Clean Interfaces**: Well-defined APIs between systems
- **Event-Driven Design**: Signal-based communication for loose coupling
- **Resource Efficiency**: Minimal memory footprint and cleanup discipline
- **State Consistency**: Proper synchronization between all game systems

### **Testing & Quality Assurance**
- **Performance Testing**: Verify 60FPS under maximum load conditions on all difficulties
- **System Integration**: Ensure all signals and systems interact correctly
- **User Experience**: Validate intuitive controls and clear feedback
- **Data Persistence**: Verify save/load functionality across sessions
- **Difficulty Scaling**: Ensure proper balance across all 4 difficulty levels

### **Future Development Readiness**
- **Phase 3 Foundation**: Graphics improvements, UI/UX enhancements, visual polish
- **Scalable Architecture**: Easy addition of new visual effects, UI elements, animations
- **Localization Ready**: String externalization for international support
- **Platform Adaptation**: Structure supports multiple deployment targets

## Phase 3 Focus: Graphics Improvements

With game logic complete, Phase 3 focuses entirely on visual enhancements:

### **Priority Areas**
1. **UI/UX Design**: More attractive and intuitive interface elements
2. **Visual Effects**: Enhanced explosions, transitions, particle systems
3. **Art Improvements**: More detailed pixel art, better visual consistency
4. **Animation Polish**: Smoother transitions, better feedback animations

### **Technical Considerations**
- **Maintain Performance**: All visual improvements must preserve 60FPS
- **Preserve Functionality**: Graphics changes should not affect game logic
- **Enhance Accessibility**: Visual improvements should aid player understanding
- **Consistent Style**: Maintain coherent visual language throughout

This architecture represents a complete, commercial-quality bullet hell shooter with sophisticated systems integration, high performance, and comprehensive player-focused features. The codebase is now ready for Phase 3 visual enhancements to achieve professional-level presentation quality.