# Vajra 2.0

<div align="center">

**A robust UCI chess engine written in [V](https://vlang.io/)**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![V](https://img.shields.io/badge/language-V-blue.svg)](https://vlang.io/)
[![UCI](https://img.shields.io/badge/protocol-UCI-green.svg)](https://www.chessprogramming.org/UCI)

*Fast, tactical, and UCI-compliant*

</div>

## 🎯 Overview

Vajra 2.0 is a UCI-compliant chess engine combining the pedagogical clarity of Tom Kerrigan's Simple Chess Program (TSCP) with modern search and evaluation techniques. Written in the V programming language, it offers C-like performance with clean, maintainable code.

## 💪 Strength

**Estimated Rating:** Approximately 1600-1700 Elo

**Search Speed:** ~365K nodes/second

## ✨ Key Features

### 🔍 Search Algorithm
- **Negamax with Alpha-Beta Pruning** - Efficient minimax variant
- **Transposition Table** - 64 MB hash table with Zobrist hashing for position caching
- **Null Move Pruning** - Forward pruning for significant tree reduction
- **Iterative Deepening** - Progressive depth increase with time management
- **Quiescence Search** - Tactical search extension to avoid horizon effect
- **Move Ordering Optimizations:**
  - Principal Variation (PV) following
  - Killer move heuristic (2 per ply)
  - History heuristic for quiet moves
  - MVV/LVA (Most Valuable Victim/Least Valuable Attacker) for captures
- **Check Extensions** - Extends search when in check
- **Repetition Detection** - Proper 3-fold repetition with smart draw claiming
- **Mate Distance Pruning** - Optimized mate finding

### 📊 Evaluation Function

**Positional Understanding:**
- **Center Control** - Bonuses for central pawn and piece placement
- **Piece Development** - Rewards for early piece activation
- **Bishop Pair** - Bonus for having both bishops
- **Knight Outposts** - Rewards for supported knights in enemy territory
- **Pawn Structure Analysis:**
  - Passed pawns with exponential scaling (10cp → 180cp by rank)
  - Penalties for doubled, isolated, and backward pawns
  - Discourages premature wing pawn advances
- **Rook Placement** - Bonuses for open files and 7th rank
- **King Safety** - Pawn shield evaluation, penalties for exposed files
- **Game Phase Awareness** - Different priorities for opening/middlegame/endgame

### 🏗️ Architecture
- **Zero-Allocation Move Generation** - Pre-allocated move stacks minimize GC pauses
- **Zobrist Hashing** - Incremental position hashing for fast position recognition
- **UCI Protocol** - Full Universal Chess Interface support
- **Efficient Board Representation** - 64-square array with validation

## 🚀 Download & Compilation

### Prerequisites
- [V Compiler](https://github.com/vlang/v) (Latest stable version recommended)

### Easy Compilation (Recommended)

**Windows:**
Run `compile.bat` and select your build type:
```cmd
compile.bat
```
- **Option 1:** Development Build (fast compilation, includes debug info)
- **Option 2:** Production Build (optimized for performance)

**Linux / macOS:**
```bash
chmod +x compile.sh
sudo ./compile.sh
```
Follow the interactive menu to select your build type.

### Manual Compilation

**Development Build:**
```bash
v -g main.v -o bin/vajra2
```

**Production Build:**
```bash
v -prod main.v -o bin/vajra2
```

The compiled executable will be in the `bin/` directory.

### Usage

Vajra is designed to work with any UCI-compatible chess GUI:

1. **Download a Chess GUI:**
   - [Arena Chess GUI](http://www.playwitharena.de/)
   - [CuteChess](https://cutechess.com/)
   - [BanksiaGUI](https://banksiagui.com/)
   - [ChessGUI](http://www.chessgui.com/)
   - [Shredder](https://www.shredderchess.com/)

2. **Add Vajra as an Engine:**
   - In your GUI, select "Add Engine" or "Manage Engines"
   - Browse to the compiled executable (`bin/vajra2.exe` on Windows, `bin/vajra2` on Linux/macOS)
   - Set protocol to **UCI**

3. **Start playing or analyzing!**

**Quick Test:**
```bash
# Test UCI protocol
echo "uci" | ./bin/vajra2
```

## 🏆 UCI Compatibility

Vajra 2.0 is UCI-compliant and works with standard chess interfaces:

### UCI Features
✅ **Full UCI Protocol:** Standard UCI support  
✅ **Hash Configuration:** Configurable hash table size  
✅ **No Built-in Book:** Clean engine without embedded opening books  
✅ **No Position Learning:** Pure search-based play  
✅ **Tournament Compatible:** Works with major chess GUIs and tournament managers  
✅ **Pondering Support:** Can be enabled/disabled  
✅ **Time Management:** Proper time control handling  

### Recommended Settings
```
Hash=64 (or 128/256 for better performance)
Threads=1 (single-threaded engine)
Ponder=Off
```

Vajra can use any generic opening book in standard formats (CTG, BIN, PGN).

## 📈 Performance

### Match Results vs TSCP 1.83

**6-game match (3 minutes per game):**
- **Score:** Vajra 4.5 - TSCP 1.5 (75%)
- **Record:** 3 wins, 0 losses, 3 draws
- **Elo Improvement:** ~100+ Elo over TSCP

**Key Achievements:**
- Successfully finds and executes forced mates
- Proper UCI mate score display (`mate 5` instead of `cp 9999`)
- Strong positional play with improved opening phase
- No critical bugs in repetition or mate detection

### Search Performance
- **Nodes Searched:** ~365K nodes/second (depth 10 from startpos)
- **Typical Depth:** 8-12 ply in middlegame (3s/move)
- **Mate Finding:** Reliable mate detection up to mate-in-15+

## 🔧 Technical Details

### Move Ordering Priority
1. **PV Move** (10,000,000) - From previous iteration
2. **TT Move** (9,000,000) - From transposition table
3. **Captures** (1,000,000 + MVV/LVA) - Most valuable victim first
4. **Killer #1** (900,000) - Primary killer move
5. **Killer #2** (800,000) - Secondary killer move
6. **History** (depth-based) - Quiet move bonus

### Transposition Table
- **Size:** 64 MB (configurable)
- **Replacement:** Depth-preferred with aging
- **Entry Types:** Exact, Alpha (upper bound), Beta (lower bound)
- **Features:** Mate score adjustment, best move storage

### Recent Enhancements

**Search Improvements:**
- Fixed repetition detection to not block mate searches
- Repetition draw only claimed when no winning alternative exists
- Minimum depth requirement before stopping on mate scores
- Proper mate distance calculation and UCI output

**Evaluation Enhancements:**
- Center control evaluation for pawns and knights
- Development bonuses for piece activation in opening
- Bishop pair bonus (+30 centipawns)
- Pawn storm penalties to prevent premature king-side weaknesses
- Knight outpost recognition and bonuses
- Game phase awareness for context-sensitive evaluation

## 🤝 Contributing

Contributions are welcome! Areas of interest:
- Evaluation function tuning
- Additional search optimizations
- Opening book implementation
- Endgame tablebase support
- Bug fixes and performance improvements

### Testing

Vajra has a comprehensive test suite to ensure code quality. Before contributing:

```bash
# Run all tests
v test tests

# Run specific test file
v test tests/board_test.v
```

See [TESTING.md](TESTING.md) for detailed testing documentation.

## 📝 Credits

- **Original Design:** [TSCP](http://www.tckerrigan.com/Chess/TSCP/) by Tom Kerrigan
- **V Port & Enhancements:** Aritra (with GitHub Copilot assistance)
- **Inspiration:** Chess Programming Wiki community

## 📜 License

Vajra 2.0 is free software licensed under the **MIT License**.

You are free to:
- ✅ Use it commercially
- ✅ Modify and distribute
- ✅ Use in private projects
- ✅ Include in testing suites and tournaments

See [LICENSE](LICENSE) for full terms.

## 🔗 Resources

- [V Programming Language](https://vlang.io/)
- [Chess Programming Wiki](https://www.chessprogramming.org/)
- [UCI Protocol Specification](https://www.chessprogramming.org/UCI)
- [Computer Chess Rating Lists](https://www.computerchess.org.uk/ccrl/)
- [Original TSCP by Tom Kerrigan](http://www.tckerrigan.com/Chess/TSCP/)

## 🙏 Acknowledgments

- **Tom Kerrigan** - Original TSCP design and implementation
- **V Language Team** - Excellent programming language and tooling
- **Chess Programming Community** - Invaluable knowledge sharing
- **GitHub Copilot** - Development assistance

---

<div align="center">

**Built with the V programming language**

*UCI-compliant • Open Source • Tournament-ready*

</div>
