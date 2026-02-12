module main

// Generate pseudo-legal moves
pub fn (b Board) gen(mut moves []Move) {
	// Assumes moves is pre-allocated and appended to
	for i in 0 .. 64 {
		if b.color[i] == b.side {
			p := b.piece[i]
			if p == pawn {
				b.gen_pawn_moves(i, mut moves)
			} else {
				// Sliding / Non-sliding pieces
				// Use 120 board for moves
				slide_piece := slide[p]
				offset_count_val := offsets_count[p]
				
				for j in 0 .. offset_count_val {
					// offset[p] is inner array
					off := offset[p*8 + j]
					
					mut n_120 := mailbox64[i] + off
					mut n_64 := mailbox[n_120]
					
					for n_64 != -1 {
						if b.color[n_64] != empty {
							if b.color[n_64] == b.xside {
								// Capture
								moves << Move{
									from: i
									to: n_64
									bits: m_capture
									promote: 0
									score: 0
								}
							}
							break // Blocked
						}
						// Non-capture
						moves << Move{
							from: i
							to: n_64
							bits: 0
							promote: 0
							score: 0
						}
						
						if !slide_piece { break }
						
						n_120 += off
						n_64 = mailbox[n_120]
					}
				}
			}
		}
	}
	
	// Castling
	b.gen_castling(mut moves)
	
	// En Passant
	if b.ep != -1 {
		b.gen_ep(mut moves)
	}

	// Remove return moves
}

fn (b Board) gen_pawn_moves(i int, mut moves []Move) {
	// White P moves Up (-8). Black P moves Down (+8).
	col := i & 7
	row := i >> 3
	
	if b.side == light { // White
		// Push
		if b.color[i - 8] == empty {
			b.add_pawn_move(i, i - 8, 0, mut moves)
			// Double push (Rank 2 -> Row 6)
			if row == 6 && b.color[i - 16] == empty {
				moves << Move{
					from: i
					to: i - 16
					bits: m_pawn_start
					promote: 0
					score: 0
				}
			}
		}
		// Capture Left (col must be > 0). i - 9.
		if col > 0 && b.color[i - 9] == dark {
			b.add_pawn_move(i, i - 9, m_capture, mut moves)
		}
		// Capture Right (col must be < 7). i - 7.
		if col < 7 && b.color[i - 7] == dark {
			b.add_pawn_move(i, i - 7, m_capture, mut moves)
		}
	} else { // Black
		// Push +8
		if b.color[i + 8] == empty {
			b.add_pawn_move(i, i + 8, 0, mut moves)
			// Double push (Rank 7 -> Row 1)
			if row == 1 && b.color[i + 16] == empty {
				moves << Move{
					from: i
					to: i + 16
					bits: m_pawn_start
					score: 0
					promote: 0
				}
			}
		}
		// Capture Left (col > 0) -> +7
		if col > 0 && b.color[i + 7] == light {
			b.add_pawn_move(i, i + 7, m_capture, mut moves)
		}
		// Capture Right (col < 7) -> +9
		if col < 7 && b.color[i + 9] == light {
			b.add_pawn_move(i, i + 9, m_capture, mut moves)
		}
	}
}

fn (b Board) add_pawn_move(from int, to int, bits int, mut moves []Move) {
	// Check promotion
	// White promotes on Row 0 (Rank 8). Black on Row 7 (Rank 1).
	row_to := to >> 3
	if row_to == 0 || row_to == 7 {
		moves << Move{from: from, to: to, bits: bits | m_promote, promote: queen, score: 0} 
		moves << Move{from: from, to: to, bits: bits | m_promote, promote: rook, score: 0} 
		moves << Move{from: from, to: to, bits: bits | m_promote, promote: bishop, score: 0} 
		moves << Move{from: from, to: to, bits: bits | m_promote, promote: knight, score: 0} 
	} else {
		moves << Move{from: from, to: to, bits: bits, promote: 0, score: 0}
	}
}

// Rewriting make_pawn_move logic to append directly in gen_pawn_moves is cleaner for promotions
// But needed to finish this function.
// Let's rely on "Move" having a promote field. 
// For full correctness, need 4 moves.
// I will keep it simple: defaulting to Queen. 
// TODO: Add N, B, R promotions.

fn (b Board) gen_castling(mut moves []Move) {
	if b.side == light {
		if (b.castle & 1) != 0 { // White King Side (E1->G1)
			// Check empty: F1(61), G1(62)
			if b.color[f1] == empty && b.color[g1] == empty {
				// Check attacks: E1, F1, G1 not attacked
				if !b.attack(e1, dark) && !b.attack(f1, dark) && !b.attack(g1, dark) {
					moves << Move{from: e1, to: g1, bits: m_castle, promote: 0, score: 0}
				}
			}
		}
		if (b.castle & 2) != 0 { // White Queen Side (E1->C1)
			// Empty: D1(59), C1(58), B1(57)
			if b.color[d1] == empty && b.color[c1] == empty && b.color[b1] == empty {
				if !b.attack(e1, dark) && !b.attack(d1, dark) && !b.attack(c1, dark) {
					moves << Move{from: e1, to: c1, bits: m_castle, promote: 0, score: 0}
				}
			}
		}
	} else {
		if (b.castle & 4) != 0 { // Black King Side (E8->G8)
			if b.color[f8] == empty && b.color[g8] == empty {
				if !b.attack(e8, light) && !b.attack(f8, light) && !b.attack(g8, light) {
					moves << Move{from: e8, to: g8, bits: m_castle, promote: 0, score: 0}
				}
			}
		}
		if (b.castle & 8) != 0 { // Black Queen Side (E8->C8)
			if b.color[d8] == empty && b.color[c8] == empty && b.color[b8] == empty {
				if !b.attack(e8, light) && !b.attack(d8, light) && !b.attack(c8, light) {
					moves << Move{from: e8, to: c8, bits: m_castle, promote: 0, score: 0}
				}
			}
		}
	}
}

fn (b Board) gen_ep(mut moves []Move) {
	// ep is the square skipped over. 
	// White P moves e2-e4. ep is e3.
	// Black P at d4 captures e3.
	// b.ep is the target square.
	
	ep_sq := b.ep
	col := ep_sq & 7
	
	if b.side == light {
		// White to move. Capturing en passant.
		// ep square is row 2 (index ~20).
		// Pawn is at ep+8 (row 3).
		// Only capture if pawn at ep+7 or ep+9 (which is ep+8-1, ep+8+1)
		// Wait. 
		// If ep is at e6 (White can capture on e6). Black moved e7-e5.
		// White pawn at d5/f5.
		// ep=44 (e6 is rank 3? No e6 is rank 6. Row 2.)
		// 44.
		// Candidate pawn: 44+7 = 51? No.
		// Candidate pawn at row 3 (Rank 5). e5=36.
		// 36+...
		// Let's simply check diagonals from ep.
		// White captures UP (-8 is move). Diagonals from pawn are -7, -9.
		// Pawn is at P. P-7 = ep. => P = ep+7.
		// Pawn is at P. P-9 = ep. => P = ep+9.
		
		// Check capture from Left (ep+7 ? No check col/row)
		// ep+7: if valid and is pawn.
		// Need `col(ep) != 7` for `ep+9` (Right check? No)
		// Check 1: Pawn at ep+9. (My pawn at ep+9, captures ep which is -9 away).
		// Condition: P(ep+9) is White Pawn.
		// ep+9 is source. Valid?
		if col != 7 && b.piece[ep_sq + 9] == pawn && b.color[ep_sq + 9] == light {
			moves << Move{from: ep_sq + 9, to: ep_sq, bits: m_ep | m_capture, promote: 0, score: 0}
		}
		// Check 2: Pawn at ep+7. (My pawn at ep+7, captures ep which is -7 away).
		if col != 0 && b.piece[ep_sq + 7] == pawn && b.color[ep_sq + 7] == light {
			moves << Move{from: ep_sq + 7, to: ep_sq, bits: m_ep | m_capture, promote: 0, score: 0}
		}
	} else {
		// Black captures en passant. Target ep is Rank 3 (Row 5).
		// Pawn is at Row 4.
		// Black moves Down (+8). Captures +7, +9.
		// P + 7 = ep => P = ep - 7.
		// P + 9 = ep => P = ep - 9.
		
		if col != 0 && b.piece[ep_sq - 9] == pawn && b.color[ep_sq - 9] == dark {
			moves << Move{from: ep_sq - 9, to: ep_sq, bits: m_ep | m_capture, promote: 0, score: 0}
		}
		if col != 7 && b.piece[ep_sq - 7] == pawn && b.color[ep_sq - 7] == dark {
			moves << Move{from: ep_sq - 7, to: ep_sq, bits: m_ep | m_capture, promote: 0, score: 0}
		}
	}
}
