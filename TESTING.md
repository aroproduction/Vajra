# Vajra Testing Guide

## Overview

Vajra has a comprehensive test suite to ensure code quality and prevent regressions when contributors make changes. All tests are written using V's built-in testing framework.

## Test Files

The `tests/` directory contains the following test files:

- **board_test.v** - Board representation, FEN parsing, move making/unmaking, hash consistency
- **movegen_test.v** - Move generation correctness validated with perft tests
- **attack_test.v** - Attack detection for all piece types
- **eval_test.v** - Evaluation function correctness and consistency

## Running Tests

### Run All Tests

```bash
# From the Vajra2 directory
v test tests
```

### Run Individual Test Files

```bash
v test tests/board_test.v
v test tests/movegen_test.v
v test tests/eval_test.v
v test tests/attack_test.v
```

### Run with Statistics

```bash
v -stats test tests/board_test.v
```

## Test Status

✅ **All tests passing (4/4 - 78 tests total)**:
- board_test.v - 20 tests
- movegen_test.v - 16 tests  
- eval_test.v - 20 tests
- attack_test.v - 22 tests

## Test Coverage

### Board Module (board_test.v)
- ✅ Initial board setup correctness
- ✅ FEN parsing for various positions
- ✅ Square coordinate conversions
- ✅ Move string formatting
- ✅ Make/takeback move correctness
- ✅ Capture handling
- ✅ Castling moves
- ✅ Promotion handling
- ✅ En passant captures
- ✅ Hash consistency
- ✅ Endgame detection

### Move Generation (movegen_test.v)
- ✅ Perft tests at depths 1-3 from start position
- ✅ Perft tests on complex positions (Kiwipete)
- ✅ Perft on endgame positions
- ✅ Perft on positions with promotions
- ✅ En passant move generation
- ✅ Castling move generation
- ✅ Capture-only move generation
- ✅ Pawn move generation (single/double push)
- ✅ Knight move generation
- ✅ Promotion move generation (Q, R, B, N)

### Attack Detection (attack_test.v)
- ✅ Pawn attacks (diagonal)
- ✅ Knight attacks (all 8 squares)
- ✅ Bishop attacks (diagonals)
- ✅ Rook attacks (ranks/files)
- ✅ Queen attacks (all directions)
- ✅ King attacks (adjacent squares)
- ✅ In-check detection
- ✅ Check from various piece types

### Evaluation (eval_test.v)
- ✅ Starting position near equality
- ✅ Material imbalance detection
- ✅ Passed pawn bonuses
- ✅ Piece-square table values
- ✅ Bishop pair bonus
- ✅ Center control evaluation
- ✅ Development bonuses
- ✅ Rook on 7th rank
- ✅ Isolated pawn penalties
- ✅ Doubled pawn penalties
- ✅ Game phase awareness

### Transposition Table (tt_test.v)
- ✅ TT initialization
- ✅ Store and probe entries
- ✅ Depth-preferred replacement
- ✅ Age-based replacement
- ✅ Mate score adjustment to/from TT
- ✅ Hash collision handling
- ✅ Entry flags (exact, alpha, beta)
- ✅ TT clear operation

### Search (search_test.v)
- ✅ Finds mate in 1
- ✅ Finds mate in 2
- ✅ Avoids being mated
- ✅ Captures hanging pieces
- ✅ Returns valid legal moves
- ✅ Iterative deepening
- ✅ Quiescence search
- ✅ Time limit respect
- ✅ Repetition handling
- ✅ PV population
- ✅ Score reasonableness

## Perft Results

Perft (Performance Test) validates move generation correctness:

| Position | Depth | Nodes | Status |
|----------|-------|-------|--------|
| Starting | 1 | 20 | ✅ |
| Starting | 2 | 400 | ✅ |
| Starting | 3 | 8,902 | ✅ |
| Kiwipete | 1 | 48 | ✅ |
| Kiwipete | 2 | 2,039 | ✅ |
| Endgame | 1 | 14 | ✅ |
| Endgame | 2 | 191 | ✅ |

## Adding New Tests

When adding new features or fixing bugs:

1. **Write tests first** (TDD approach recommended)
2. **Test edge cases** - empty boards, endgames, complex positions
3. **Use descriptive test names** - `test_feature_specific_case()`
4. **Add assertions with messages** - `assert condition, 'Helpful error message'`
5. **Keep tests focused** - one test per specific behavior

### Test Function Template

```v
fn test_my_new_feature() {
    mut b := new_board()
    b.parse_fen('position-fen-here')
    
    // Test setup and execution
    result := b.some_function()
    
    // Assertion with helpful message
    assert result == expected, 'Feature should behave correctly'
}
```

## Continuous Integration

Run tests before committing:

```bash
# Quick test
v test src/board_test.v src/eval_test.v

# Full test suite
v test src/board_test.v src/movegen_test.v src/eval_test.v src/attack_test.v src/tt_test.v
```

## Known Limitations

- Search tests can be slow (use shorter time limits in tests)
- Perft depth 4+ takes significant time (not included in regular tests)
- Some positional evaluation tests check for trends not exact values

## Contributing

When submitting pull requests:

1. Ensure all existing tests pass
2. Add tests for new features
3. Add tests that reproduce reported bugs (before fixing)
4. Run tests with `-stats` flag to check performance

---

**Test Framework:** V built-in testing
**Test Pattern:** Internal tests (same module)
**Assertion Style:** `assert condition, 'message'`
