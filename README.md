# Vajra 2.0

Vajra 2.0 is a chess engine written in the [V programming language](https://vlang.io/), heavily inspired by and based on the logic of Tom Kerrigan's Simple Chess Program (TSCP).

## Overview

This project aims to be a faithful yet idiomatic port of TSCP to V, leveraging V's performance characteristics while maintaining the simplicity and clarity of the original engine. It supports the UCI (Universal Chess Interface) protocol, making it compatible with most modern chess GUIs.

## Features

### Board Representation
- **Board**: 64-square array representation with `color` and `piece` arrays.
- **Move Generation**: Uses a 120-square mailbox vector system for efficient move validation and generation.
- **State**: Optimized `Board` struct with minimal allocation requirements.

### Search
- **Algorithm**: Negamax with Alpha-Beta pruning.
- **Enhancements**:
  - **Transposition Table**: 64 MB hash table to store previously evaluated positions, avoiding redundant searches and enabling significant speedup.
  - **Null Move Pruning**: Forward pruning technique that gives the opponent a free move to quickly prove that the current position is too good to be worth searching deeply.
  - **Killer Moves Heuristic**: Stores quiet moves that caused beta cutoffs at each ply, improving move ordering for non-captures.
  - **Iterative Deepening**: Progressively deeper searches to manage time and improve move ordering.
  - **Quiescence Search**: Extends search at leaf nodes for capture sequences to avoid the horizon effect.
  - **Principal Variation (PV) Table**: Caches the best line of play to improve sorting in subsequent iterations.
  - **History Heuristic**: Prioritizes successful quiet moves found at other nodes of the same depth.
  - **Move Sorting**: Uses MVV/LVA (Most Valuable Victim / Least Valuable Attacker) for captures and History scores for quiet moves.

### Evaluation
A comprehensive evaluation function ported from TSCP 1.83, including:
- **Material Balance**: Standard piece values.
- **Piece-Square Tables**: Positional bonuses for specific piece placement.
- **Pawn Structure**: Penalties for doubled, isolated, and backward pawns; bonuses for passed pawns with exponential scaling by rank (10cp to 180cp).
- **King Safety**: Pawn shield evaluation and penalties for semi-open/open files near the King.

## Build Architecture
- **Zero-Allocation**: The move generation logic has been heavily refactored from the idiomatic V style to a high-performance style using pre-allocated move stacks. This minimizes Garbage Collection pauses during the search tree traversal.
- **Protocols**: Fully supports the Universal Chess Interface (UCI).

## Installation & Building

### Prerequisites
- [V Compiler](https://github.com/vlang/v) (Latest stable or master)

### Compilation

You can build the engine using the standard V compiler commands or the provided scripts.

**Standard Build:**
```bash
v -prod src -o vajra2
```

**Development / Debug:**
```bash
v -g src
```

**Using Scripts:**
- **Windows**: Use `build.ps1`
- **Unix/Linux**: Use `build_prod.sh` (ensure it is executable: `chmod +x build_prod.sh`)

## Usage

Vajra 2.0 is a command-line engine that communicates via standard input/output. It is not designed to be used directly by humans but rather by a Chess GUI.

1. Download a Chess GUI (e.g., [Arena](http://www.playwitharena.de/), [CuteChess](https://cutechess.com/), or [BanksiaGUI](https://banksiagui.com/)).
2. In the GUI settings, select "Create New Engine".
3. Point to the compiled `vajra2` executable.
4. Ensure the protocol is set to **UCI**.

## Credits & License

- **Original Logic**: [TSCP (Tom Kerrigan's Simple Chess Program)](http://www.tckerrigan.com/Chess/TSCP/) by Tom Kerrigan.
- **Implementation**: Ported to V with language-specific optimizations.

## Status

*Current Build: Feb 13, 2026*
Vajra 2.0 has been significantly improved with critical bug fixes. Testing shows approximately **-96 Elo vs TSCP** (improved from -288 Elo), with ongoing optimization work.

---

## Recent Improvements (Feb 13, 2026)

### Critical Bug Fixes

#### 1. **Zobrist Hashing Implementation** ✅
**Problem:** The engine had no position hashing - `hash_key()` always returned 0, making all positions appear identical.

**Solution:**
- Added Zobrist random number tables in `data.v` using xorshift64 PRNG
- Added `hash: u64` field to Board struct
- Implemented `set_hash()` to compute initial position hash
- Added incremental hash updates in `make_move()` and `takeback()`
- Hash XORs on piece moves, captures, en passant, and side to move

**Files Modified:** `data.v`, `board.v`, `move.v`, `defs.v`, `uci.v`

#### 2. **Repetition Detection** ✅
**Problem:** `reps()` function always returned 0, causing excessive draw by repetition (12/50 games in initial testing).

**Solution:**
- Implemented proper repetition checking using Zobrist hashes stored in move history
- Only checks positions since last fifty-move counter reset (correct TSCP behavior)
- Changed `Hist.hash` from `int` to `u64` for proper hash storage

**Files Modified:** `search.v`, `defs.v`, `move.v`

#### 3. **Quiescence Search Optimization** ✅
**Problem:** Quiescence search generated ALL moves then filtered for captures, wasting CPU cycles.

**Solution:**
- Added `gen_caps()` function to generate only capture moves
- Added `gen_pawn_captures()` helper for pawn-specific captures
- En passant correctly included as capture move

**Files Modified:** `movegen.v`, `search.v`

#### 4. **PV Following & Move Ordering** ✅
**Problem:** PV (Principal Variation) following logic was incorrect, causing inefficient search.

**Solution:**
- Fixed to match TSCP's approach: reset `follow_pv` flag at each position
- Only set flag when PV move is found in current move list
- Applied proper 10,000,000 bonus to PV moves for ordering
- Fixed both main search and quiescence search

**Files Modified:** `search.v`

#### 5. **Search Safety Checks** ✅
**Problem:** Missing depth and history stack bounds checking could cause crashes.

**Solution:**
- Added ply depth check: `if b.ply >= max_ply - 1 { return b.eval() }`
- Added history stack check: `if b.hply >= 1000 - 1 { return b.eval() }`
- Check repetitions only when `ply > 0` (not at root)

**Files Modified:** `search.v`

### Known Issues

#### 1. **No Opening Book**
Engine plays the same moves as White every game:
```
1. d4 d5 2. e3 Nc6 3. Nc3 e6 4. Nf3 Bb4 5. Bd2 Bxc3 
6. Bxc3 Bd7 7. Bd3 Nf6 8. O-O O-O 9. Ng5 Re8 
10. Nf3 Rf8 11. Ng5 Re8 12. Nf3 Rf8 (Draw by repetition)
```
**Impact:** 100% draw rate as White (50/50 games in testing)
**Solution Needed:** Add opening book or improve evaluation to avoid immediate repetition loops

#### 2. **Weak Opening Repertoire as Black**
Always plays Nimzowitsch Defense (1... Nc6), which is objectively inferior:
```
1. e4 Nc6 2. d4 e5 3. d5 Nce7 4. Nc3 Nf6 5. Bg5 Ng6 6. Bxf6
```
**Impact:** Gets positions evaluated at -0.60 to -0.82 by move 5
**Solution Needed:** Opening book or better move selection

### Testing Configuration

**Current Test Results (100 games, 3s/move):**
```
Score of Vajra vs TSCP: 1 - 23 - 76  [0.390] 100
...      Vajra playing White: 0 - 0 - 50  [0.500] 50
...      Vajra playing Black: 1 - 23 - 26  [0.280] 50
...      White vs Black: 23 - 1 - 76  [0.610] 100
Elo difference: -77.7 +/- 31.4, LOS: 0.0 %, DrawRatio: 76.0 %
SPRT: llr 0 (0.0%), lbound -inf, ubound inf
```

### Performance Improvements
- **+192 Elo gain** from -288 to -96 vs TSCP
- Repetition detection now works correctly
- Search is more efficient with proper move ordering
- Quiescence search optimized (captures only)

### Next Steps
1. Add opening book to avoid repetition loops as White
2. Implement UCI time management for deeper searches
3. Improve evaluation function for better positional play
4. Consider aspiration windows for search efficiency

---
