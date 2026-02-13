module main

pub struct Board {
pub mut:
	color  [64]int
	piece  [64]int
	side   int
	xside  int
	castle int
	ep     int
	fifty  int
	hply   int // History ply (moves since start of game)
	ply    int // Search ply (distance from root)
	hist   []Hist
	hash   u64 // Zobrist hash
}

pub fn new_board() Board {
	mut b := Board{
		ep: -1
		hist: []Hist{cap: 1000} // Pre-alloc
	}
	b.init_board()
	return b
}

pub fn (mut b Board) init_board() {
	// 0-7: a8-h8 (Black pieces)
	// 8-15: a7-h7 (Black pawns)
	// 48-55: a2-h2 (White pawns)
	// 56-63: a1-h1 (White pieces)

	for i in 0 .. 64 {
		b.color[i] = empty
		b.piece[i] = empty
	}

	// Place pieces manually like TSCP or via FEN?
	// TSCP does it manually. Let's do it manually for standard start.
	
	// White pieces
	b.place_pieces(light, 56) // rank 1
	b.place_pawns(light, 48)  // rank 2

	// Black pieces
	b.place_pieces(dark, 0)   // rank 8
	b.place_pawns(dark, 8)    // rank 7

	b.side = light
	b.xside = dark
	b.castle = 15 // 1|2|4|8 - all allowed
	b.ep = -1
	b.fifty = 0
	b.hply = 0
	b.ply = 0
	
	// Initialize hash
	b.set_hash()
}

// Check if we're in endgame (for null move pruning)
// Simple heuristic: endgame if side to move has only king + pawns or very little material
pub fn (b Board) is_endgame() bool {
	mut material := 0
	for i in 0 .. 64 {
		if b.color[i] == b.side && b.piece[i] != king && b.piece[i] != pawn {
			material += piece_value[b.piece[i]]
		}
	}
	// Endgame if we have less than a rook's worth of non-pawn material
	return material < 500
}

fn (mut b Board) place_pieces(c int, start_sq int) {
	b.color[start_sq + 0] = c; b.piece[start_sq + 0] = rook
	b.color[start_sq + 1] = c; b.piece[start_sq + 1] = knight
	b.color[start_sq + 2] = c; b.piece[start_sq + 2] = bishop
	b.color[start_sq + 3] = c; b.piece[start_sq + 3] = queen
	b.color[start_sq + 4] = c; b.piece[start_sq + 4] = king
	b.color[start_sq + 5] = c; b.piece[start_sq + 5] = bishop
	b.color[start_sq + 6] = c; b.piece[start_sq + 6] = knight
	b.color[start_sq + 7] = c; b.piece[start_sq + 7] = rook
}

fn (mut b Board) place_pawns(c int, start_sq int) {
	for i in 0 .. 8 {
		b.color[start_sq + i] = c
		b.piece[start_sq + i] = pawn
	}
}

pub fn (b Board) get_fen() string {
	// TODO: Generate FEN
	return "" 
}

// Simple parser for UCI 'position fen ...'
// Not full validation, just loading
pub fn (mut b Board) parse_fen(fen string) {
	parts := fen.split(' ')
	if parts.len < 1 { return }
	
	// Reset board
	for i in 0 .. 64 {
		b.color[i] = empty
		b.piece[i] = empty
	}

	// 1. Piece placement
	rows := parts[0].split('/')
	for r, row_str in rows {
		// TSCP board: Rank 8 is index 0-7 (row 0)
		// FEN starts with Rank 8
		// checking alignment: FEN Rank 8 -> Board 0..7. Matches TSCP Layout.
		mut col := 0
		for c in row_str {
			if c >= `1` && c <= `8` { // FEN uses 1-8
				col += int(c - `0`)
			} else {
				// piece char
				mut p := empty
				mut color := light
				if c >= `A` && c <= `Z` {
					color = light
				} else {
					color = dark
				}
				
				low_c := if c >= `A` && c <= `Z` { c + 32 } else { c }
				match low_c {
					`p` { p = pawn }
					`n` { p = knight }
					`b` { p = bishop }
					`r` { p = rook }
					`q` { p = queen }
					`k` { p = king }
					else {}
				}
				
				index := r * 8 + col
				b.color[index] = color
				b.piece[index] = p
				col++
			}
		}
	}

	// 2. Side to move
	if parts.len > 1 {
		if parts[1] == "w" {
			b.side = light
			b.xside = dark
		} else {
			b.side = dark
			b.xside = light
		}
	}

	// 3. Castling
	b.castle = 0
	if parts.len > 2 {
		if parts[2].contains("K") { b.castle |= 1 }
		if parts[2].contains("Q") { b.castle |= 2 }
		if parts[2].contains("k") { b.castle |= 4 }
		if parts[2].contains("q") { b.castle |= 8 }
	}

	// 4. En passant
	b.ep = -1
	if parts.len > 3 && parts[3] != "-" {
		// Convert e3 to square index
		// e3 -> col 4, rank 3 (from 1)
		// Board index: Rank 8 is row 0. Rank 3 is row 5.
		// file 'a' is 0. 'e' is 4.
		// sq = row * 8 + col = 5 * 8 + 4 = 44?
		// Helper: str_to_sq
		file := parts[3][0]
		rank := parts[3][1]
		col := int(file) - int(`a`)
		row := 8 - (int(rank) - int(`0`)) // '3' -> 3. 8-3 = 5
		b.ep = row * 8 + col
	}

	// 5. Halfmove clock
	if parts.len > 4 {
		b.fifty = parts[4].int()
	}
	
	// Initialize hash after parsing
	b.set_hash()
}

pub fn (b Board) print() {
	println("  a b c d e f g h")
	for r in 0 .. 8 {
		print("${8-r} ")
		for c in 0 .. 8 {
			sq := r * 8 + c
			if b.color[sq] == empty {
				if (r + c) % 2 == 0 {
					print(". ")
				} else {
					print("  ") // dark square
				}
			} else {
				p := b.piece[sq]
				mut char_p := " "
				match p {
					pawn { char_p = "p" }
					knight { char_p = "n" }
					bishop { char_p = "b" }
					rook { char_p = "r" }
					queen { char_p = "q" }
					king { char_p = "k" }
					else {}
				}
				if b.color[sq] == light {
					print(char_p.to_upper() + " ")
				} else {
					print(char_p + " ")
				}
			}
		}
		println(" ${8-r}")
	}
	println("  a b c d e f g h")
}

pub fn (mut b Board) move_from_str(s string) Move {
	mut moves := []Move{cap: 100}
	b.gen(mut moves)
	for m in moves {
		if m.str() == s {
			return m
		}
	}
	// Return invalid? empty move
	return Move{from:0, to:0, bits:0, score:0} 
}

pub fn (mut b Board) perft(depth int) u64 {
	if depth == 0 { return 1 }
	mut moves := []Move{cap: 100}
	b.gen(mut moves)
	mut nodes := u64(0)
	for m in moves {
		if b.make_move(m) {
			nodes += b.perft(depth - 1)
			b.takeback()
		}
	}
	return nodes
}

// Zobrist hash initialization
pub fn (mut b Board) set_hash() {
	b.hash = 0
	for i in 0..64 {
		if b.color[i] != empty {
			b.hash ^= hash_piece[b.color[i]][b.piece[i]][i]
		}
	}
	if b.side == dark {
		b.hash ^= hash_side
	}
	if b.ep != -1 {
		b.hash ^= hash_ep[b.ep]
	}
}
