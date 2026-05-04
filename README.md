# Dr. Mario — MIPS Assembly

A fully playable implementation of Dr. Mario built entirely in MIPS assembly, running on a 64×64 bitmap display in the Saturn simulator. Written from scratch as a final project for CSC258 (Computer Organization) at the University of Toronto.

---

## Features

- **Full game loop** — gravity, collision detection, capsule spawning, game over condition
- **Capsule mechanics** — 4 orientations (horizontal, vertical, and their reverses), free rotation with `w`, movement in all directions
- **Virus generation** — randomized placement, color, and count (3–12 viruses per game) across the lower portion of the bottle
- **Match detection** — horizontal and vertical 4-in-a-row clearing for both capsule halves and viruses
- **Gravity-driven piece dropping** — after matches clear, floating pieces fall into place iteratively until the board stabilizes
- **Increasing difficulty** — gravity threshold decrements over time, making capsules fall faster as the game progresses
- **Pause and reset** — pause mid-game with `p`, restart at any time with `r`
- **Fever Theme music** — the classic Dr. Mario Fever theme plays in the background using MIPS sound syscalls (guitar + organ parts)
- **Sound effects** — distinct sounds on capsule move and rotation
- **Dr. Mario sprite** — pixel art character drawn on the display

---

## Controls

| Key | Action         |
|-----|----------------|
| `a` | Move left      |
| `d` | Move right     |
| `s` | Move down      |
| `w` | Rotate capsule |
| `p` | Pause          |
| `r` | Reset game     |
| `q` | Quit           |

---

## How It Works

### Display
The game renders to a 64×64 bitmap display (2×2 pixel units) mapped to memory address `0x10008000`. All drawing is done by computing memory offsets directly — horizontal position is a left-shift by 2 (4 bytes per pixel), vertical position is a left-shift by 7 (128 bytes per row).

### Grid Representation
The bottle interior is a 16×22 word array in `.data`. Each cell stores a color index:
- `0` = Red
- `1` = Yellow  
- `2` = Blue
- `3` = Black (empty)
- `4` = White (wall/boundary)

### Capsule
The active capsule is stored as a struct: x, y, orientation (0–3), two pill color indices, and an active status flag. Each frame the capsule is erased, updated, and redrawn.

### Virus System
Up to 12 viruses are stored in a parallel array with (x, y, color) per entry. Viruses use darker color variants (`0xAA0000`, `0xAAAA00`, `0x0000AA`) to distinguish them visually from capsule pills. They are checked against during match detection and gravity — viruses do not fall.

### Match & Clear Logic
After every capsule placement, the board scans for 4-in-a-row horizontally and vertically. Matched cells are cleared to black. A gravity pass then iterates bottom-up, dropping any unsupported pieces (checking below, left, and right for support), repeating until no more pieces move.

### Music
The Fever theme is encoded as two parallel note arrays (`fever_guitar`, `fever_organ`) with 138 and 74 notes respectively. Each game loop tick advances the playback position, playing the next note via the MIPS sound syscall (`syscall 31`).

---
---

## Implementation Notes

- All memory management is done manually — no heap allocation, registers saved/restored on the stack at every function call per MIPS calling conventions
- The game loop runs continuously; gravity is frame-counted rather than timer-based, incrementing a counter each loop and triggering a drop when it hits the threshold
- Collision detection handles all four orientations independently to correctly compute the second pill's position offset
- The board uses sentinel boundary values (color `4`) in the first row to prevent reads from going out of bounds

---

## Authors

- Laith Al Khoury
- Thiyaan Karunanayake

University of Toronto — CSC258H1, Winter 2025
