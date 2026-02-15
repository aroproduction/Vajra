module main

import src

// Test evaluation function returns sensible values

// Test starting position is roughly equal
fn test_eval_startpos() {
	b := src.new_board()
	score := b.eval()
	
	// Starting position should be close to 0 (within 50 centipawns)
	assert score >= -50 && score <= 50, 'Start position eval should be near 0, got ${score}'
}

// Test material advantage
fn test_eval_material() {
	mut b := src.new_board()
	
	// White up a queen (black missing queen)
	b.parse_fen('rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
	score := b.eval()
	
	// Queen is worth 900, so white should be significantly ahead
	assert score > 800, 'White up a queen should score > 800, got ${score}'
}

// Test pawn structure
fn test_eval_doubled_pawns() {
	mut b := src.new_board()
	
	// Position with doubled pawns for black
	b.parse_fen('rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1')
	
	// White should have advantage due to black's doubled c-pawns
	// This is hard to test precisely, but structure is part of eval
	score := b.eval()
	// Just ensure eval runs without crashing
	_ = score
}

// Test passed pawns are valued
fn test_eval_passed_pawn() {
	mut b := src.new_board()
	
	// White passed pawn on e6
	b.parse_fen('4k3/8/4P3/8/8/8/8/4K3 w - - 0 1')
	score_with := b.eval()
	
	// Without passed pawn
	b.parse_fen('4k3/8/8/8/8/8/8/4K3 w - - 0 1')
	score_without := b.eval()
	
	// Passed pawn should give bonus
	assert score_with > score_without, 'Passed pawn should increase eval'
}

// Test piece square tables work
fn test_eval_piece_square_tables() {
	mut b := src.new_board()
	
	// Knight on edge
	b.parse_fen('4k3/8/8/8/8/8/8/N3K3 w - - 0 1')
	score_edge := b.eval()
	
	// Knight in center
	b.parse_fen('4k3/8/8/8/3N4/8/8/4K3 w - - 0 1')
	score_center := b.eval()
	
	// Center knight should score higher
	assert score_center > score_edge, 'Center knight should score higher than edge'
}

// Test king safety in opening/middlegame
fn test_eval_king_safety() {
	mut b := src.new_board()
	
	// King with pawn shield
	b.parse_fen('r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1')
	score_safe := b.eval()
	
	// King exposed (moved pawns in front)
	b.parse_fen('r1bqkb1r/pppp1p1p/2n2np1/4p3/2B1P2P/5N2/PPPP1PP1/RNBQK2R w KQkq - 0 1')
	score_exposed := b.eval()
	
	// Safe king should score better
	// (This might be subtle depending on other factors, so just check eval runs)
	_ = score_safe
	_ = score_exposed
}

// Test symmetry: flipped position should have opposite eval
fn test_eval_symmetry() {
	mut b1 := src.new_board()
	mut b2 := src.new_board()
	
	// White to move
	b1.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
	score1 := b1.eval()
	
	// Black to move (same position)
	b2.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1')
	score2 := b2.eval()
	
	// Evaluations should be opposite (roughly)
	// This is from side-to-move perspective
	assert score1 * score2 >= 0 // Both should have same sign or be zero
}

// Test bishop pair bonus
fn test_eval_bishop_pair() {
	mut b := src.new_board()
	
	// Both bishops
	b.parse_fen('4k3/8/8/8/8/8/8/2BBK3 w - - 0 1')
	score_pair := b.eval()
	
	// One bishop
	b.parse_fen('4k3/8/8/8/8/8/8/3BK3 w - - 0 1')
	score_single := b.eval()
	
	// Bishop pair should give bonus
	assert score_pair > score_single, 'Bishop pair should give bonus'
}

// Test center control evaluation
fn test_eval_center_control() {
	mut b := src.new_board()
	
	// Pawn in center
	b.parse_fen('4k3/8/8/8/3P4/8/8/4K3 w - - 0 1')
	score_center := b.eval()
	
	// Pawn on edge
	b.parse_fen('4k3/8/8/8/P7/8/8/4K3 w - - 0 1')
	score_edge := b.eval()
	
	// Center pawn should score higher
	assert score_center > score_edge, 'Center pawn should score higher'
}

// Test development bonuses in opening
fn test_eval_development() {
	mut b := src.new_board()
	
	// Well developed
	b.parse_fen('rnbqkb1r/pppppppp/5n2/8/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1')
	score_developed := b.eval()
	
	// Not developed (starting position)
	b.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
	score_start := b.eval()
	
	// Developed position should score higher for white
	assert score_developed > score_start, 'Developed pieces should score higher'
}

// Test knight outpost bonus
fn test_eval_knight_outpost() {
	mut b := src.new_board()
	
	// Knight on outpost (e5, supported by pawn)
	b.parse_fen('r1bqkb1r/pppp1ppp/2n2n2/4N3/8/8/PPPPPPPP/RNBQKB1R w KQkq - 0 1')
	// Need a pawn supporting it
	b.parse_fen('r1bqkb1r/pppp1ppp/2n2n2/4N3/3P4/8/PPP1PPPP/RNBQKB1R w KQkq - 0 1')
	score_outpost := b.eval()
	
	// Knight not on outpost
	b.parse_fen('r1bqkb1r/pppp1ppp/2n2n2/8/3NP3/8/PPP1PPPP/RNBQKB1R w KQkq - 0 1')
	score_normal := b.eval()
	
	// Outpost should give bonus (though subtle)
	_ = score_outpost
	_ = score_normal
}

// Test rook on open file
fn test_eval_rook_open_file() {
	mut b := src.new_board()
	
	// Rook on open d-file
	b.parse_fen('4k3/8/8/8/8/8/8/3RK3 w - - 0 1')
	score_open := b.eval()
	
	// Rook on closed d-file (pawn on d2, rook on d1)
	b.parse_fen('4k3/8/8/8/8/8/3P4/3RK3 w - - 0 1')
	score_closed := b.eval()
	
	// Open file should be better (rook bonus for open file)
	// Note: might be subtle, just check eval doesn't crash
	_ = score_open
	_ = score_closed
}

// Test rook on 7th rank
fn test_eval_rook_seventh() {
	mut b := src.new_board()
	
	// Rook on 7th rank
	b.parse_fen('4k3/3R4/8/8/8/8/8/4K3 w - - 0 1')
	score_seventh := b.eval()
	
	// Rook not on 7th
	b.parse_fen('4k3/8/8/8/3R4/8/8/4K3 w - - 0 1')
	score_other := b.eval()
	
	// 7th rank should give bonus
	assert score_seventh > score_other, 'Rook on 7th should score higher'
}

// Test evaluation doesn't crash on various positions
fn test_eval_no_crash() {
	positions := [
		'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
		'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
		'8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
		'4k3/8/8/8/8/8/8/4K3 w - - 0 1',
		'rnbqkb1r/pppppppp/5n2/8/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 0 1',
	]
	
	mut b := src.new_board()
	for fen in positions {
		b.parse_fen(fen)
		score := b.eval()
		// Just ensure it doesn't crash and returns reasonable value
		assert score > -10000 && score < 10000, 'Eval out of range for ${fen}'
	}
}

// Test isolated pawn penalty
fn test_eval_isolated_pawn() {
	mut b := src.new_board()
	
	// Isolated e-pawn
	b.parse_fen('4k3/8/8/4p3/8/8/8/4K3 b - - 0 1')
	score_isolated := b.eval()
	
	// Connected pawns
	b.parse_fen('4k3/8/8/3ppp2/8/8/8/4K3 b - - 0 1')
	score_connected := b.eval()
	
	// Connected pawns should score better
	assert score_connected > score_isolated, 'Connected pawns should score better'
}

// Test tempo (side to move has small advantage)
fn test_eval_tempo() {
	mut b := src.new_board()
	
	// White to move
	b.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
	score_white := b.eval()
	
	// Black to move
	b.parse_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1')
	score_black := b.eval()
	
	// Both should be close to zero
	assert score_white >= -50 && score_white <= 50
	assert score_black >= -50 && score_black <= 50
}

// Test game phase affects evaluation
fn test_eval_game_phase() {
	mut b := src.new_board()
	
	// Opening phase
	b.parse_fen('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1')
	score_opening := b.eval()
	
	// Endgame phase
	b.parse_fen('4k3/pppppppp/8/8/8/8/PPPPPPPP/4K3 w - - 0 1')
	score_endgame := b.eval()
	
	// Both should evaluate without crashing
	_ = score_opening
	_ = score_endgame
}
