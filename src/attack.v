module src

// Check if square sq is attacked by side s
// sq is 64-sq index.
pub fn (b Board) attack(sq int, s int) bool {
	sq_120 := mailbox64[sq]
	
	// Check Pawns
	if s == light {
		// Attacked by White Pawn? (White moves -10)
		// White pawn at sq+11 or sq+9 attacks sq (via -11 / -9)
		if b.is_piece_at_120(sq_120 + 11, light, pawn) { return true }
		if b.is_piece_at_120(sq_120 + 9, light, pawn) { return true }
	} else {
		// Attacked by Black Pawn? (Black moves +10)
		// Black pawn at sq-11 or sq-9 attacks sq (via +11 / +9)
		if b.is_piece_at_120(sq_120 - 11, dark, pawn) { return true }
		if b.is_piece_at_120(sq_120 - 9, dark, pawn) { return true }
	}

	// Knight
	for i in 0 .. 8 {
		off := offset[knight*8 + i]
		// Inverse of Knight move is same as move (symmetric)
		// So check if Knight at sq+off attacks sq?
		// No, usually we check if piece at sq-off attacks sq.
		// Knight moves are symmetric. If A attacks B, B attacks A.
		// So check if there is a knight at sq+off.
		if b.is_piece_at_120(sq_120 + off, s, knight) { return true }
	}
	
	// King
	for i in 0 .. 8 {
		off := offset[king*8 + i]
		if b.is_piece_at_120(sq_120 + off, s, king) { return true }
	}

	// Sliding Pieces
	// Diagonals (Bishop/Queen)
	// Orthogonals (Rook/Queen)
	
	// Bishop/Queen
	for i in 0 .. 4 {
		off := offset[bishop*8 + i]
		if b.check_slide(sq_120, s, bishop, off) { return true }
	}
	
	// Rook/Queen
	for i in 0 .. 4 {
		off := offset[rook*8 + i] // 0..4 Use Rook offsets
		if b.check_slide(sq_120, s, rook, off) { return true }
	}

	return false
}

fn (b Board) is_piece_at_120(idx_120 int, s int, p int) bool {
	sq_64 := mailbox[idx_120]
	if sq_64 != -1 {
		if b.color[sq_64] == s && b.piece[sq_64] == p {
			return true
		}
	}
	return false
}

fn (b Board) check_slide(start_120 int, s int, p int, off int) bool {
	mut curr := start_120 + off
	mut sq_64 := mailbox[curr]
	
	for sq_64 != -1 {
		if b.color[sq_64] != empty {
			if b.color[sq_64] == s && (b.piece[sq_64] == p || b.piece[sq_64] == queen) {
				return true
			}
			return false // Blocked
		}
		curr += off
		sq_64 = mailbox[curr]
	}
	return false
}

pub fn (b Board) in_check(s int) bool {
	mut king_sq := -1
	for i in 0 .. 64 {
		if b.piece[i] == king && b.color[i] == s {
			king_sq = i
			break
		}
	}
	if king_sq == -1 { 
		// Keep sane, maybe returning false is unsafe but better than crash
		return false 
	}
	// Check if King is attacked by opponent (s ^ 1)
	return b.attack(king_sq, s ^ 1) // s^1 flips 0->1, 1->0
}
