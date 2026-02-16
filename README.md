# Vajra 2.0

<div align="center">

**A UCI chess engine written in [V](https://vlang.io/)**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![V](https://img.shields.io/badge/language-V-blue.svg)](https://vlang.io/)
[![UCI](https://img.shields.io/badge/protocol-UCI-green.svg)](https://www.chessprogramming.org/UCI)

*Approximately 1600-1700 Elo • ~365K nps*

Based on [TSCP](http://www.tckerrigan.com/Chess/TSCP/) by Tom Kerrigan

</div>

## Features

**Search:** Negamax, alpha-beta pruning, transposition table, null move pruning, iterative deepening, quiescence search, move ordering (PV/killer/history/MVV-LVA)

**Evaluation:** Material, piece-square tables, pawn structure, king safety, mobility, game phase awareness

**Architecture:** UCI compliant, Zobrist hashing, zero-allocation move generation

## Compilation

Requires [V compiler](https://github.com/vlang/v)

```bash
# Interactive (recommended)
compile.bat              # Windows
./compile.sh             # Linux/macOS

# Manual
v -prod main.v -o bin/vajra2
```

## Usage

Works with any UCI chess GUI (Arena, CuteChess, BanksiaGUI, etc.)

**Recommended Settings:**
```
Hash=64-256 MB
Threads=1
Ponder=Off
```

Supports external opening books (CTG, BIN, PGN).

## Testing

```bash
v test tests             # Run all tests (78 tests)
```

See [TESTING.md](TESTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE)

## Resources

- [V Language](https://vlang.io/)
- [Chess Programming Wiki](https://www.chessprogramming.org/)
- [UCI Protocol](https://www.chessprogramming.org/UCI)
