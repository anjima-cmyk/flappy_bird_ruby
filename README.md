# 🐦 Flappy Bird — Ruby / Gosu

A complete Flappy Bird implementation in Ruby using the **Gosu** game library.
No image assets needed — everything is drawn with Gosu primitives.

---

## Project Structure

```
flappy_bird/
├── main.rb               # Entry point
├── Gemfile               # Dependencies
├── README.md
└── lib/
    ├── constants.rb      # All tunable game constants
    ├── bird.rb           # Bird physics, rotation, wing animation
    ├── pipe_manager.rb   # Pipe spawning, scrolling, collision, scoring
    └── game_loop.rb      # Gosu window, state machine, HUD, overlays
```

---

## Prerequisites

- **Ruby** 2.7+ (3.x recommended)
- **Gosu** dependencies vary by OS:

### macOS
```bash
brew install sdl2
gem install gosu
```

### Ubuntu / Debian
```bash
sudo apt-get install build-essential libsdl2-dev libsdl2-ttf-dev \
  libpango1.0-dev libgl1-mesa-dev libopenal-dev libsndfile-dev
gem install gosu
```

### Windows
Gosu ships pre-built on Windows:
```bash
gem install gosu
```

---

## Installation

```bash
cd flappy_bird
bundle install
```

---

## Running the Game

```bash
ruby main.rb
```

---

## Controls

| Key / Action       | Effect            |
|--------------------|-------------------|
| `SPACE` / `Click`  | Flap / Start / Restart |
| `ESC`              | Quit              |

---

## Game States

```
IDLE  ──(SPACE)──►  PLAYING  ──(collision)──►  DEAD  ──(SPACE)──► PLAYING
```

---

## Tuning Constants (`lib/constants.rb`)

| Constant           | Default | Description                        |
|--------------------|---------|------------------------------------|
| `GRAVITY`          | `0.5`   | Downward acceleration per frame    |
| `FLAP_FORCE`       | `-9.0`  | Upward velocity impulse on flap    |
| `TERMINAL_VEL`     | `12.0`  | Maximum fall speed                 |
| `PIPE_SPEED`       | `3.0`   | Pipe scroll speed (px/frame)       |
| `PIPE_GAP`         | `160`   | Vertical gap between pipe pair     |
| `PIPE_SPAWN_INTERVAL` | `90` | Frames between pipe spawns         |

---

## Features Implemented

- ✅ Physics: gravity, flap impulse, terminal velocity
- ✅ Bird rotation tied to vertical velocity (nose-up / nose-down)
- ✅ Animated wing flap (3-state: mid / up / down)
- ✅ Randomly positioned pipe gaps, fixed gap size
- ✅ Pipes removed when off-screen
- ✅ One-hit death
- ✅ Score increments when bird centre passes pipe pair
- ✅ Score pop-up animation on pipe pass
- ✅ Best score persisted across sessions (`~/.flappy_bird_best`)
- ✅ Game states: idle → playing → dead → restart
- ✅ Background parallax (clouds + mountains)
- ✅ Scrolling ground
- ✅ HUD with score + best score overlay panels
- ✅ No external image assets required

---

## Architecture

```
GameLoop (Gosu::Window)
 ├─ Bird           — physics entity + renderer
 ├─ PipeManager    — collection of Pipe structs
 │   └─ Pipe       — scroll, collision, draw
 └─ Constants      — shared module included everywhere
```

Each component is in its own file under `lib/`, keeping concerns separated
exactly as the curriculum requires.
