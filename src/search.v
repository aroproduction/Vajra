module main

import time

pub const max_depth = 64
pub const infinite = 20000
pub const mate_score = 10000

pub struct Search {
pub mut:
	nodes      u64
	stop_time  i64
	stop       bool
	
	// PV Table
	pv_table   [64][64]Move
	pv_length  [64]int
	follow_pv  bool
	
	// History
	history    [64][64]int
	
	// Move Stack (Pre-allocated)
	move_stack []Move
	first_move [65]int
	
	// Transposition Table
	tt         TranspositionTable
	
	// Killer Moves (2 per ply)
	killers    [64][2]Move
}

pub fn new_search() Search {
	return Search{
		move_stack: []Move{len: 0, cap: 20000} // Pre-allocate ample space
		tt: new_tt(64) // 64 MB transposition table
	}
}

// Result struct to return best move
pub struct SearchResult {
pub:
	best_move Move
	score     int
	nodes     u64
}

pub fn (mut s Search) think(mut b Board, depth_limit int, time_limit_ms int) SearchResult {
	s.nodes = 0
	s.stop = false
	s.stop_time = 0
	
	// Reset search ply
	b.ply = 0
	
	// Increment TT age
	s.tt.new_search()
	
	// Clear killers
	for i in 0 .. 64 {
		s.killers[i][0] = Move{}
		s.killers[i][1] = Move{}
	}
	
	// Reset stats?
	// Keep history? TSCP clears history: memset(history, 0, sizeof(history));
	// But usually history is kept between searches? TSCP clears it.
	for i in 0 .. 64 {
		for j in 0 .. 64 {
			s.history[i][j] = 0
		}
	}
	
	start_time := time.now().unix_milli()
	if time_limit_ms > 0 {
		s.stop_time = start_time + time_limit_ms
	} else {
		s.stop_time = start_time + 10000000 // Infinite
	}

	mut best_move := Move{}
	mut score := 0
	
	// Iterative Deepening
	for depth := 1; depth <= depth_limit; depth++ {
		s.follow_pv = true
		s.first_move[0] = 0 // Reset move stack index
		s.move_stack.trim(0) // Reset stack
		
		score = s.search(mut b, -infinite, infinite, depth)
		
		// If stopped, break? 
		// TSCP logic: if stop_search, return.
		if s.stop {
			break
		}
		
		// Get best move from PV
		best_move = s.pv_table[0][0]
		
		// Output Info string (UCI)
		elapsed := time.now().unix_milli() - start_time
		nps := if elapsed > 0 { s.nodes * 1000 / u64(elapsed) } else { 0 }
		
		// Format score: check if it's a mate score
		if score > 9000 {
			// Positive mate score - we're mating opponent
			mate_in := (mate_score - score + 1) / 2
			print("info depth $depth score mate $mate_in nodes $s.nodes time $elapsed nps $nps pv")
		} else if score < -9000 {
			// Negative mate score - we're being mated
			mate_in := -(mate_score + score + 1) / 2
			print("info depth $depth score mate $mate_in nodes $s.nodes time $elapsed nps $nps pv")
		} else {
			print("info depth $depth score cp $score nodes $s.nodes time $elapsed nps $nps pv")
		}
		for i in 0 .. s.pv_length[0] {
			print(" " + s.pv_table[0][i].str())
		}
		println("")
		
		if score > 9000 || score < -9000 { 
			// Found a mate - but only stop if we've searched at least depth 3
			// This ensures we find mates-in-1 properly (need depth 2+)
			if depth >= 3 {
				break
			}
		}
	}
	
	return SearchResult{best_move: best_move, score: score, nodes: s.nodes}
}

fn (mut s Search) search(mut b Board, alpha int, beta int, depth int) int {
	// Check time/interrupt
	if (s.nodes & 2047) == 0 {
		s.check_time()
	}
	if s.stop { return 0 }

	s.pv_length[b.ply] = b.ply
	
	// Probe transposition table
	tt_hit := s.tt.probe(b.hash) or { TTEntry{} }
	mut tt_move := Move{}
	
	if tt_hit.hash == b.hash {
		tt_move = tt_hit.best
		
		// TT cutoff: use stored value if depth is sufficient
		// BUT: Don't allow cutoffs at root (ply=0) - we need to find the actual best move
		if b.ply > 0 && tt_hit.depth >= depth {
			mut tt_score := int(tt_hit.score)
			tt_score = s.tt.adjust_mate_score_from_tt(tt_score, b.ply)
			
			if tt_hit.flag == tt_exact {
				return tt_score
			} else if tt_hit.flag == tt_alpha && tt_score <= alpha {
				return alpha
			} else if tt_hit.flag == tt_beta && tt_score >= beta {
				return beta
			}
		}
	}

	if depth == 0 {
		return s.quiesce(mut b, alpha, beta)
	}
	
	s.nodes++
	
	// Only check 50-move rule as a FORCED draw
	// Don't check repetitions here - they should be handled as draw options, not forced
	if b.fifty >= 100 { return 0 }
	
	// Depth safety check
	if b.ply >= max_ply - 1 { return b.eval() }
	if b.hply >= 1000 - 1 { return b.eval() }
	
	// Check extension
	in_check := b.in_check(b.side)
	mut new_depth := depth - 1
	if in_check { new_depth++ }
	
	// Null Move Pruning
	// Give opponent a free move - if we're still better than beta, prune this branch
	// Don't use in: check positions, endgame, when last move was null, at low depths
	do_null := !in_check 
		&& b.ply > 0  // Not at root
		&& depth >= 3  // Sufficient depth
		&& !b.is_endgame()  // Not in endgame
	
	if do_null {
		// Make null move
		b.make_null_move()
		
		// Initialize first_move for the null move ply
		s.first_move[b.ply] = s.move_stack.len
		
		// Reduced depth search with null window
		null_score := -s.search(mut b, -beta, -beta + 1, depth - 3)
		
		b.undo_null_move()
		
		if s.stop { return 0 }
		
		// Null move cutoff
		if null_score >= beta {
			return beta
		}
	}
	
	// Generate Moves using Stack
	mut first_idx := s.first_move[b.ply]
	// Ensure stack is trimmed to current ply start (important for consistency, though recursion handles it)
	// Actually, just append.
	if s.move_stack.len > first_idx {
		s.move_stack.trim(first_idx)
	} else if s.move_stack.len < first_idx {
		// If first_move[ply] is beyond current stack length, reset it
		s.first_move[b.ply] = s.move_stack.len
		first_idx = s.move_stack.len
	}
	
	b.gen(mut s.move_stack)
	last_idx := s.move_stack.len
	s.first_move[b.ply + 1] = last_idx
	
	count := last_idx - first_idx
	
	// Score moves directly in move_stack
	for i in 0 .. count {
		idx := first_idx + i
		mut m := s.move_stack[idx]
		s.move_stack[idx].score = s.score_move(mut b, m, tt_move)
	}
	
	// PV following - sort_pv equivalent
	if s.follow_pv {
		s.follow_pv = false  // Reset
		for i in 0 .. count {
			idx := first_idx + i
			m := s.move_stack[idx]
			if b.ply < s.pv_length[0] && m.is_same(s.pv_table[0][b.ply]) {
				s.follow_pv = true
				s.move_stack[idx].score += 10000000
				break
			}
		}
	}
	
	mut legal_moves := 0
	mut alpha_local := alpha
	mut best_move := Move{}
	
	// Selection Sort Loop
	for _ in 0 .. count {
		// Pick best
		mut best_idx := -1
		mut best_score := -100000000
		for j in 0 .. count {
			// Check score directly from stack
			s_score := s.move_stack[first_idx + j].score
			if s_score > best_score {
				best_score = s_score
				best_idx = j
			}
		}
		
		if best_score == -100000000 { break } // All done
		
		// Mark picked used
		s.move_stack[first_idx + best_idx].score = -100000001
		
		m := s.move_stack[first_idx + best_idx]
		
		if !b.make_move(m) {
			continue
		}
		legal_moves++

		val := -s.search(mut b, -beta, -alpha_local, new_depth)
		
		b.takeback()
		
		if s.stop { return 0 }
		
		if val > alpha_local {
			best_move = m
			
			// Update History
			// Correct logic matching TSCP:
			// "if not capture" -> if (m.bits & 1) == 0.
			// m_capture is 1.
			if (m.bits & m_capture) == 0 { 
				s.history[m.from][m.to] += depth
			}
			
			if val >= beta {
				// Store killer move for non-captures
				if (m.bits & m_capture) == 0 {
					// Shift killers down
					s.killers[b.ply][1] = s.killers[b.ply][0]
					s.killers[b.ply][0] = m
				}
				
				// Store in TT
				tt_score := s.tt.adjust_mate_score_to_tt(beta, b.ply)
				s.tt.store(b.hash, depth, tt_beta, tt_score, m)
				
				return beta
			}
			alpha_local = val
			
			// Update PV
			s.pv_table[b.ply][b.ply] = m
			// Copy next ply PV
			// Logic: pv[ply][j] = pv[ply+1][j]
			next_ply := b.ply + 1
			// Bounds check?
			if next_ply < 64 {
				len := s.pv_length[next_ply]
				s.pv_length[b.ply] = len
				for j in next_ply .. len {
					if j < 64 {
						s.pv_table[b.ply][j] = s.pv_table[next_ply][j]
					}
				}
			}
		}
	}
	
	if legal_moves == 0 {
		if in_check {
			return -mate_score + b.ply // Mated
		} else {
			return 0 // Stalemate
		}
	}
	
	// Check for 3-fold repetition ONLY if we don't have a winning position
	// Repetition is a CLAIM, not forced - only use it if we're not winning
	if b.ply > 0 && alpha_local <= 0 && b.reps() >= 2 {
		// Position occurred 2+ times before (3-fold total)
		// And our best move doesn't give us an advantage
		// Claim draw by repetition
		alpha_local = 0
	}
	
	// Store in transposition table
	mut tt_flag := tt_alpha
	if alpha_local > alpha {
		tt_flag = tt_exact  // PV node
	}
	tt_score := s.tt.adjust_mate_score_to_tt(alpha_local, b.ply)
	s.tt.store(b.hash, depth, tt_flag, tt_score, best_move)
	
	return alpha_local
}

fn (mut s Search) quiesce(mut b Board, alpha int, beta int) int {
	if (s.nodes & 2047) == 0 { s.check_time() }
	if s.stop { return 0 }
	
	s.nodes++
	s.pv_length[b.ply] = b.ply
	
	// Stand pat (static eval)
	stand_pat := b.eval()
	if stand_pat >= beta {
		return beta
	}
	
	mut alpha_local := alpha
	if stand_pat > alpha_local {
		alpha_local = stand_pat
	}
	
	// Generate Captures only
	mut first_idx := s.first_move[b.ply]
	if s.move_stack.len > first_idx { 
		s.move_stack.trim(first_idx) 
	} else if s.move_stack.len < first_idx {
		s.first_move[b.ply] = s.move_stack.len
		first_idx = s.move_stack.len
	}
	
	b.gen_caps(mut s.move_stack)
	last_idx := s.move_stack.len
	s.first_move[b.ply + 1] = last_idx
	
	count := last_idx - first_idx
	
	// Score moves for capture ordering
	for i in 0 .. count {
		idx := first_idx + i
		mut m := s.move_stack[idx]
		s.move_stack[idx].score = s.score_move(mut b, m, Move{})
	}
	
	// PV following in quiescence
	if s.follow_pv {
		s.follow_pv = false
		for i in 0 .. count {
			idx := first_idx + i
			m := s.move_stack[idx]
			if b.ply < s.pv_length[0] && m.is_same(s.pv_table[0][b.ply]) {
				s.follow_pv = true
				s.move_stack[idx].score += 10000000
				break
			}
		}
	}
	
	for _ in 0 .. count {
		mut best_idx := -1
		mut best_score := -100000000
		for j in 0 .. count {
			s_score := s.move_stack[first_idx + j].score
			if s_score > best_score {
				best_score = s_score
				best_idx = j
			}
		}
		
		if best_score == -100000000 { break }
		s.move_stack[first_idx + best_idx].score = -100000001
		
		m := s.move_stack[first_idx + best_idx]
		
		if !b.make_move(m) { continue }
		val := -s.quiesce(mut b, -beta, -alpha_local)
		b.takeback()
		
		if s.stop { return 0 }
		
		if val > alpha_local {
			if val >= beta { return beta }
			alpha_local = val
			
			s.pv_table[b.ply][b.ply] = m
			next_ply := b.ply + 1
			if next_ply < 64 {
				len := s.pv_length[next_ply]
				s.pv_length[b.ply] = len
				for j in next_ply .. len {
					if j < 64 {
						s.pv_table[b.ply][j] = s.pv_table[next_ply][j]
					}
				}
			}
		}
	}
	
	return alpha_local
}

fn (mut s Search) score_move(mut b Board, m Move, tt_move Move) int {
	// TT move gets highest priority (after PV)
	if tt_move.from != 0 && m.is_same(tt_move) {
		return 9000000
	}
	
	// Captures scored with MVV/LVA
	if (m.bits & m_capture) != 0 {
		mut victim := b.piece[m.to]
		if (m.bits & m_ep) != 0 {
			victim = pawn
		}
		
		// MVV/LVA
		// Convert piece indices to meaningful values if needed, 
		// but P=0, N=1, B=2, R=3, Q=4 works for ordering (higher is better victim).
		// Empty=6, handled above.
		
		attacker := b.piece[m.from]
		return 1000000 + (victim * 10) - attacker
	}
	
	// Killer moves (quiet moves that caused beta cutoffs at this ply)
	if m.is_same(s.killers[b.ply][0]) {
		return 900000
	}
	if m.is_same(s.killers[b.ply][1]) {
		return 800000
	}
	
	// Quiet moves scored by history heuristic
	return s.history[m.from][m.to]
}

fn (mut s Search) check_time() {
	if s.stop_time != 0 && time.now().unix_milli() > s.stop_time {
		s.stop = true
	}
}

// Helpers
fn (b Board) reps() int {
	// Check for repetitions in the history
	// Only check back to the last irreversible move (capture or pawn move)
	// which resets the fifty counter
	if b.hply == 0 { return 0 }
	
	mut count := 0
	current_hash := b.hash
	
	// Search backwards through history
	// Only check positions since last fifty reset
	start_idx := if b.hply > b.fifty { b.hply - b.fifty } else { 0 }
	
	for i in start_idx .. b.hply {
		if b.hist[i].hash == current_hash {
			count++
		}
	}
	
	return count
}

fn (m Move) is_same(other Move) bool {
	return m.from == other.from && m.to == other.to && m.bits == other.bits && m.promote == other.promote
}
