module main

import src

// Test board initialization
fn test_init_board() {
	mut b := src.new_board()
	
	// Check white pieces on rank 1
	assert b.color[src.a1] == src.light && b.piece[src.a1] == src.rook
	assert b.color[src.b1] == src.light && b.piece[src.b1] == src.knight
	assert b.color[src.c1] == src.light && b.piece[src.c1] == src.bishop
	assert b.color[src.d1] == src.light && b.piece[src.d1] == src.queen
	assert b.color[src.e1] == src.light && b.piece[src.e1] == src.king
	assert b.color[src.f1] == src.light && b.piece[src.f1] == src.bishop
	assert b.color[src.g1] == src.light && b.piece[src.g1] == src.knight
	assert b.color[src.h1] == src.light && b.piece[src.h1] == src.rook
	
	// Check white pawns on rank 2
	for i in 0 .. 8 {
		assert b.color[48 + i] == src.light && b.piece[48 + i] == src.pawn
	}
	
	// Check black pieces on rank 8
	assert b.color[src.a8] == src.dark && b.piece[src.a8] == src.rook
	assert b.color[src.b8] == src.dark && b.piece[src.b8] == src.knight
	assert b.color[src.c8] == src.dark && b.piece[src.c8] == src.bishop
	assert b.color[src.d8] == src.dark && b.piece[src.d8] == src.queen
	assert b.color[src.e8] == src.dark && b.piece[src.e8] == src.king
	assert b.color[src.f8] == src.dark && b.piece[src.f8] == src.bishop
	assert b.color[src.g8] == src.dark && b.piece[src.g8] == src.knight
	assert b.color[src.h8] == src.dark && b.piece[src.h8] == src.rook
	
	// Check black pawns on rank 7
	for i in 0 .. 8 {
		assert b.color[8 + i] == src.dark && b.piece[8 + i] == src.pawn
	}
	
	// Check empty squares in the middle
	for i in 16 .. 48 {
		assert b.color[i] == src.empty && b.piece[i] == src.empty
	}
	
	// Check initial game state
	assert b.side == src.light
	assert b.xside == src.dark
	assert b.castle == 15
	assert b.ep == -1
	assert b.fifty == 0
	assert b.hply == 0
	assert b.ply == 0
}

// Test FEN parsing
fn test_parse_fen_startpos() {
	mut b := src.new_board()
	b.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
	
	// Check positions match standard start
	assert b.color[src.e1] == src.light && b.piece[src.e1] == src.king
	assert b.color[src.e8] == src.dark && b.piece[src.e8] == src.king
	assert b.side == src.light
	assert b.castle == 15
	assert b.ep == -1
}

// Test FEN parsing with en passant
fn test_parse_fen_with_ep() {
	mut b := src.new_board()
	b.parse_fen('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1')
	
	assert b.side == src.dark
	assert b.ep == 44 // e3 square
}

// Test FEN parsing with castling rights
fn test_parse_fen_castling() {
	mut b := src.new_board()
	
	// Only white kingside
	b.parse_fen('r3k2r/8/8/8/8/8/8/R3K2R w Kq - 0 1')
	assert b.castle == 9 // K (1) + q (8)
	
	// Only black queenside
	b.parse_fen('r3k2r/8/8/8/8/8/8/R3K2R w Qk - 0 1')
	assert b.castle == 6 // Q (2) + k (4)
	
	// No castling
	b.parse_fen('r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1')
	assert b.castle == 0
}

// Test square string conversion
fn test_sq_str() {
	assert src.sq_str(src.a8) == 'a8'
	assert src.sq_str(src.e4) == 'e4'
	assert src.sq_str(src.h1) == 'h1'
	assert src.sq_str(src.d5) == 'd5'
}

// Test string to square conversion
fn test_str_to_sq() {
	assert src.str_to_sq('a8') == src.a8
	assert src.str_to_sq('e4') == src.e4
	assert src.str_to_sq('h1') == src.h1
	assert src.str_to_sq('d5') == src.d5
}

// Test move string formatting
fn test_move_str() {
	m := src.Move{from: src.e2, to: src.e4, bits: src.m_pawn_start, promote: src.empty, score: 0}
	assert m.str() == 'e2e4'
	
	// Promotion
	mp := src.Move{from: src.e7, to: src.e8, bits: src.m_promote, promote: src.queen, score: 0}
	assert mp.str() == 'e7e8q'
	
	// Regular move
	mr := src.Move{from: src.g1, to: src.f3, bits: 0, promote: src.empty, score: 0}
	assert mr.str() == 'g1f3'
}

// Test make and takeback move
fn test_make_takeback() {
	mut b := src.new_board()
	
	// Store initial hash
	initial_hash := b.hash
	
	// e2-e4
	m := src.Move{from: src.e2, to: src.e4, bits: src.m_pawn_start, promote: src.empty, score: 0}
	legal := b.make_move(m)
	assert legal
	
	// Check piece moved
	assert b.piece[src.e2] == src.empty
	assert b.piece[src.e4] == src.pawn && b.color[src.e4] == src.light
	
	// Check side flipped
	assert b.side == src.dark
	assert b.xside == src.light
	
	// Check en passant square set
	assert b.ep == 44 // e3
	
	// Takeback
	b.takeback()
	
	// Check restored
	assert b.piece[src.e2] == src.pawn && b.color[src.e2] == src.light
	assert b.piece[src.e4] == src.empty
	assert b.side == src.light
	assert b.ep == -1
	assert b.hash == initial_hash
}

// Test capture
fn test_capture() {
	mut b := src.new_board()
	
	// Set up a position with a capture: white pawn on e5, black pawn on d6
	b.parse_fen('rnbqkbnr/ppp1pppp/3p4/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1')
	
	// e5xd6
	m := src.Move{from: src.e5, to: src.d6, bits: src.m_capture | src.m_pawn, promote: src.empty, score: 0}
	legal := b.make_move(m)
	assert legal
	
	// Check captured pawn is gone and capturing pawn is on d6
	assert b.piece[src.e5] == src.empty
	assert b.piece[src.d6] == src.pawn && b.color[src.d6] == src.light
	
	// Check fifty counter reset
	assert b.fifty == 0
}

// Test castling
fn test_castling_white_kingside() {
	mut b := src.new_board()
	
	// Position ready for white kingside castling
	b.parse_fen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1')
	
	// e1g1 (castling)
	m := src.Move{from: src.e1, to: src.g1, bits: src.m_castle, promote: src.empty, score: 0}
	legal := b.make_move(m)
	assert legal
	
	// Check king and rook moved
	assert b.piece[src.g1] == src.king && b.color[src.g1] == src.light
	assert b.piece[src.f1] == src.rook && b.color[src.f1] == src.light
	assert b.piece[src.e1] == src.empty
	assert b.piece[src.h1] == src.empty
	
	// Check castling rights removed
	assert (b.castle & 3) == 0 // White castling rights gone
}

// Test promotion
fn test_promotion() {
	mut b := src.new_board()
	
	// White pawn on 7th rank ready to promote
	b.parse_fen('8/P7/8/8/8/8/8/4K2k w - - 0 1')
	
	// a7a8q
	m := src.Move{from: src.a7, to: src.a8, bits: src.m_promote | src.m_pawn, promote: src.queen, score: 0}
	legal := b.make_move(m)
	assert legal
	
	// Check pawn promoted to queen
	assert b.piece[src.a8] == src.queen && b.color[src.a8] == src.light
	assert b.piece[src.a7] == src.empty
}

// Test en passant capture
fn test_en_passant() {
	mut b := src.new_board()
	
	// Position with en passant available
	b.parse_fen('rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 1')
	
	// e5xf6 en passant
	m := src.Move{from: src.e5, to: src.f6, bits: src.m_capture | src.m_ep | src.m_pawn, promote: src.empty, score: 0}
	legal := b.make_move(m)
	assert legal
	
	// Check capturing pawn moved to f6
	assert b.piece[src.f6] == src.pawn && b.color[src.f6] == src.light
	assert b.piece[src.e5] == src.empty
	// Check captured pawn on f5 is gone
	assert b.piece[src.f5] == src.empty
}

// Test hash consistency
fn test_hash_consistency() {
	mut b1 := src.new_board()
	mut b2 := src.new_board()
	
	// Both boards should have same hash at start
	assert b1.hash == b2.hash
	
	// Make same moves on both
	m := src.Move{from: src.e2, to: src.e4, bits: src.m_pawn_start, promote: src.empty, score: 0}
	b1.make_move(m)
	b2.make_move(m)
	
	assert b1.hash == b2.hash
	
	// Takeback on b1
	b1.takeback()
	
	// Hash should be different now
	assert b1.hash != b2.hash
	
	// Make move again
	b1.make_move(m)
	assert b1.hash == b2.hash
}

// Test endgame detection
fn test_endgame_detection() {
	mut b := src.new_board()
	
	// Starting position is not endgame
	assert !b.is_endgame()
	
	// King and pawns only - endgame
	b.parse_fen('4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1')
	assert b.is_endgame()
	
	// King, bishop, pawns - endgame (< 500 centipawns)
	b.parse_fen('4k3/pppppppp/8/8/8/8/PPPPPPPP/4KB2 w - - 0 1')
	assert b.is_endgame()
	
	// King, rook, pawns - not endgame (rook = 500)
	b.parse_fen('4k3/pppppppp/8/8/8/8/PPPPPPPP/4K2R w - - 0 1')
	assert !b.is_endgame()
}

// Test move parsing from string
fn test_move_from_str() {
	mut b := src.new_board()
	
	// Regular move
	m1 := b.move_from_str('e2e4')
	assert m1.from == src.e2
	assert m1.to == src.e4
	
	// Promotion
	b.parse_fen('8/P7/8/8/8/8/8/4K2k w - - 0 1')
	m2 := b.move_from_str('a7a8q')
	assert m2.from == src.a7
	assert m2.to == src.a8
	assert m2.promote == src.queen
	assert (m2.bits & src.m_promote) != 0
}
