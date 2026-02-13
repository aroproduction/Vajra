module main

pub fn (mut b Board) make_move(m Move) bool {
	if m.bits == 0 && m.from == 0 && m.to == 0 { return false } // Null move check

	// Castling: Check if in check first (Cannot castle out of check)
	if (m.bits & m_castle) != 0 {
		if b.in_check(b.side) { return false }
		// Path checking is done in gen / should be safe if coming from gen
		// But if UCI sends castling move, validation happens here?
		// Assuming gen moves for now.
	}

	// Save history
	h := Hist{
		m: m
		capture: b.piece[m.to]
		castle: b.castle
		ep: b.ep
		fifty: b.fifty
		hash: b.hash
	}
	b.hist << h
	b.hply++
	b.ply++
	
	mut from := m.from
	mut to := m.to
	
	// Move Rook if castling
	if (m.bits & m_castle) != 0 {
		if to == g1 { // White Kingside
			b.move_piece(h1, f1)
		} else if to == c1 { // White Queenside
			b.move_piece(a1, d1)
		} else if to == g8 { // Black Kingside
			b.move_piece(h8, f8)
		} else if to == c8 { // Black Queenside
			b.move_piece(a8, d8)
		}
	}
	
	// Update En Passant captured pawn removal
	if (m.bits & m_ep) != 0 {
		if b.side == light {
			// White moves ep (e.g. e5-f6), captures f5 (to+8? No to-8? No).
			// Start: e5. End: f6. EP sq is f6. Captured pawn is at f5.
			// White capturing en passant: Target is `to`. Pawn is at `to + 8` (Rank 5 -> Row 3. Target Row 2. diff +8)
			b.hash ^= hash_piece[dark][pawn][to + 8]
			b.color[to + 8] = empty
			b.piece[to + 8] = empty
		} else {
			// Black capturing ep: Target `to`. Pawn at `to - 8`.
			b.hash ^= hash_piece[light][pawn][to - 8]
			b.color[to - 8] = empty
			b.piece[to - 8] = empty
		}
	}
	
	// Update board (Move piece)
	// Remove piece from source
	b.hash ^= hash_piece[b.side][b.piece[from]][from]
	
	// Capture: remove captured piece from target
	if (m.bits & m_capture) != 0 && (m.bits & m_ep) == 0 {
		b.hash ^= hash_piece[b.xside][b.piece[to]][to]
	}
	
	// Place piece on target (potentially promoted)
	moved_piece := if (m.bits & m_promote) != 0 { m.promote } else { b.piece[from] }
	b.hash ^= hash_piece[b.side][moved_piece][to]
	
	b.color[to] = b.side
	b.piece[to] = moved_piece
	b.color[from] = empty
	b.piece[from] = empty
	
	// Update Castle Permissions
	b.castle &= castle_mask[from] & castle_mask[to]
	// No hash update needed for castle permissions in TSCP-style
	
	// Update EP
	if b.ep != -1 {
		b.hash ^= hash_ep[b.ep]  // Remove old EP
	}
	if (m.bits & m_pawn_start) != 0 {
		if b.side == light { b.ep = to + 8 } else { b.ep = to - 8 }
		b.hash ^= hash_ep[b.ep]  // Add new EP
	} else {
		b.ep = -1
	}
	
	// Update Fifty
	if (m.bits & m_capture) != 0 || (m.bits & m_pawn) != 0 {
		b.fifty = 0
	} else {
		b.fifty++
	}
	
	// Switch side
	b.hash ^= hash_side  // Toggle side
	b.side ^= 1
	b.xside ^= 1
	
	// Verify legality (King in check?)
	// Note: We switched side. So we check if 'xside' (mover) is in check.
	if b.in_check(b.xside) {
		b.takeback()
		return false
	}
	
	return true
}

pub fn (mut b Board) takeback() {
	if b.hist.len == 0 { return }
	h := b.hist.pop()
	b.hply--
	b.ply--
	
	m := h.m
	from := m.from
	to := m.to
	
	// Restore hash
	b.hash = h.hash
	
	// Switch side back
	b.side ^= 1
	b.xside ^= 1
	
	// Undo Move Piece
	b.color[from] = b.side
	b.piece[from] = if (m.bits & m_promote) != 0 { pawn } else { b.piece[to] } // If promoted, it was a pawn
	
	// Restore captured piece
	if (m.bits & m_ep) != 0 {
		// En Passant capture: `to` is empty. Captured pawn is at offset.
		b.color[to] = empty
		b.piece[to] = empty
		
		if b.side == light {
			b.color[to + 8] = dark
			b.piece[to + 8] = pawn
		} else {
			b.color[to - 8] = light
			b.piece[to - 8] = pawn
		}
	} else {
		// Normal capture or non-capture
		if (m.bits & m_capture) != 0 {
			b.color[to] = b.xside
			b.piece[to] = h.capture
		} else {
			b.color[to] = empty
			b.piece[to] = empty
		}
	}
	
	// Undo Rook move if Castling
	if (m.bits & m_castle) != 0 {
		if to == g1 { b.move_piece(f1, h1) }
		else if to == c1 { b.move_piece(d1, a1) }
		else if to == g8 { b.move_piece(f8, h8) }
		else if to == c8 { b.move_piece(d8, a8) }
	}
	
	// Restore State
	b.castle = h.castle
	b.ep = h.ep
	b.fifty = h.fifty
}

fn (mut b Board) move_piece(from int, to int) {
	b.color[to] = b.color[from]
	b.piece[to] = b.piece[from]
	b.color[from] = empty
	b.piece[from] = empty
}

// Null move for null move pruning
pub fn (mut b Board) make_null_move() {
	// Save history
	h := Hist{
		m: Move{}  // Null move
		capture: empty
		castle: b.castle
		ep: b.ep
		fifty: b.fifty
		hash: b.hash
	}
	b.hist << h
	b.hply++
	b.ply++
	
	// Clear EP if set
	if b.ep != -1 {
		b.hash ^= hash_ep[b.ep]
		b.ep = -1
	}
	
	// Switch side
	b.hash ^= hash_side
	b.side ^= 1
	b.xside ^= 1
}

pub fn (mut b Board) undo_null_move() {
	if b.hist.len == 0 { return }
	h := b.hist.pop()
	b.hply--
	b.ply--
	
	// Restore hash
	b.hash = h.hash
	
	// Switch side back
	b.side ^= 1
	b.xside ^= 1
	
	// Restore state
	b.ep = h.ep
}
