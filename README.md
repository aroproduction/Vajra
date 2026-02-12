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
  - **Iterative Deepening**: Progressively deeper searches to manage time and improve move ordering.
  - **Quiescence Search**: Extends search at leaf nodes for capture sequences to avoid the horizon effect.
  - **Principal Variation (PV) Table**: Caches the best line of play to improve sorting in subsequent iterations.
  - **History Heuristic**: Prioritizes successful quiet moves found at other nodes of the same depth.
  - **Move Sorting**: Uses MVV/LVA (Most Valuable Victim / Least Valuable Attacker) for captures and History scores for quiet moves.

### Evaluation
A comprehensive evaluation function ported from TSCP 1.83, including:
- **Material Balance**: Standard piece values.
- **Piece-Square Tables**: Positional bonuses for specific piece placement.
- **Pawn Structure**: Penalties for doubled, isolated, and backward pawns; bonuses for passed pawns.
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

*Current Build: Feb 2026*
Vajra 2.0 is currently rated approximately 200 Elo points below standard TSCP 1.83 based on SPRT testing. Optimization work is ongoing.
