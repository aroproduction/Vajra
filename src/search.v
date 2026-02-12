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
}

pub fn new_search() Search {
	return Search{
		move_stack: []Move{len: 0, cap: 20000} // Pre-allocate ample space
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
		
		print("info depth $depth score cp $score nodes $s.nodes time $elapsed nps $nps pv")
		for i in 0 .. s.pv_length[0] {
			print(" " + s.pv_table[0][i].str())
		}
		println("")
		
		if score > 9000 || score < -9000 { break } // Mate found
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

	if depth == 0 {
		return s.quiesce(mut b, alpha, beta)
	}
	
	s.nodes++
	
	// Repetition check
	if b.reps() > 0 { return 0 }
	if b.fifty >= 100 { return 0 }
	
	// Check extension
	in_check := b.in_check(b.side)
	if in_check { 
		// Extension logic requires caution with infinite loops, 
		// but simple check extension +1 is standard.
		// Note: TSCP does check extension: if (c) ++depth;
		// But let's be careful. Pass new depth?
		// depth is parameter. 
	}
	
	// Prepare new depth
	mut new_depth := depth - 1
	if in_check { new_depth++ }
	
	// Generate Moves using Stack
	first_idx := s.first_move[b.ply]
	// Ensure stack is trimmed to current ply start (important for consistency, though recursion handles it)
	// Actually, just append.
	if s.move_stack.len > first_idx {
		s.move_stack.trim(first_idx)
	}
	
	b.gen(mut s.move_stack)
	last_idx := s.move_stack.len
	s.first_move[b.ply + 1] = last_idx
	
	count := last_idx - first_idx
	
	// Score moves directly in move_stack
	for i in 0 .. count {
		idx := first_idx + i
		// s.move_stack[idx].score = ...
		// V requires mut access? array elements are mutable if array is mut?
		// "s.move_stack[idx]" gives a value copy if struct is not a reference.
		// Wait. structs are value types.
		// If I do `m := s.move_stack[idx]`, m is a copy.
		// I must assign back: `s.move_stack[idx].score = val`.
		
		mut m := s.move_stack[idx]
		score_val := s.score_move(mut b, m)
		if s.follow_pv && b.ply < s.pv_length[0] && m.is_same(s.pv_table[0][b.ply]) {
			s.follow_pv = true
			s.move_stack[idx].score = score_val + 10000000
		} else {
			s.move_stack[idx].score = score_val
		}
	}
	
	// move_count := 0 // Unused
	mut legal_moves := 0
	mut alpha_local := alpha
	
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
		
		// PV Following Logic
		// We only continue following the PV if we are currently following it AND this move is the PV move.
		old_follow := s.follow_pv
		if s.follow_pv {
			// Check if m is the PV move
			if b.ply < s.pv_length[0] && m.is_same(s.pv_table[0][b.ply]) {
				s.follow_pv = true
			} else {
				s.follow_pv = false
			}
		}

		val := -s.search(mut b, -beta, -alpha_local, new_depth)
		
		// Restore PV state
		s.follow_pv = old_follow

		b.takeback()
		
		if s.stop { return 0 }
		
		if val > alpha_local {
			// Update History
			// Correct logic matching TSCP:
			// "if not capture" -> if (m.bits & 1) == 0.
			// m_capture is 1.
			if (m.bits & m_capture) == 0 { 
				s.history[m.from][m.to] += depth
			}
			
			if val >= beta {
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
	first_idx := s.first_move[b.ply]
	if s.move_stack.len > first_idx { s.move_stack.trim(first_idx) }
	
	b.gen(mut s.move_stack)
	last_idx := s.move_stack.len
	s.first_move[b.ply + 1] = last_idx
	
	count := last_idx - first_idx
	
	// Score moves directly in move_stack
	for i in 0 .. count {
		idx := first_idx + i
		mut m := s.move_stack[idx] 
		if (m.bits & m_capture) == 0 && (m.bits & m_promote) == 0 {
			s.move_stack[idx].score = -100000001
		} else {
			s.move_stack[idx].score = s.score_move(mut b, m)
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

fn (mut s Search) score_move(mut b Board, m Move) int {
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
	// Quiet
	return s.history[m.from][m.to]
}

fn (mut s Search) check_time() {
	if s.stop_time != 0 && time.now().unix_milli() > s.stop_time {
		s.stop = true
	}
}

// Helpers
fn (b Board) reps() int {
	// Check history for repetitions
	// Loop from 0 to hply-1
	// Count how many times current hash appears.
	// Since we don't have incremental hash history, 
	// we rely on Move history and reconstructing? Too slow.
	
	// Fast approach if we had `hist []u64` of hashes.
	// `b.hist` is `[]Hist`. `Hist` has `hash u64`.
	// We should use it.
	
	if b.hply == 0 { return 0 }
	
	// TSCP uses `hash_b` and `hash_w`.
	// Let's assume `b.hash_key()` generates current hash.
	// We need to compare current hash with previous positions.
	
	// Wait, if Zobrist isn't implemented (func returns 0), checks fail.
	// I need Zobrist first.
	// If Zobrist is not available, I can't check repetitions efficiently.
	
	// TSCP doesn't use Zobrist for Repetition? 
	// TSCP uses `hash` struct member in `hist`.
	// "The program relies on the hash variables to detect repetitions."
	
	// If I haven't implemented Zobrist updates in `make_move`, `hist[i].hash` is 0.
	// `b.hash_key()` returns 0.
	// So 0 == 0 always.
	// If `reps()` checks:
	/*
	    for i in 0 .. b.hply {
	        if b.hist[i].hash == current_hash { count++ }
	    }
	*/
	// If everything is 0, count = hply.
	// reps > 0 always. returns 0 score.
	// Engine never moves? No, `search` proceeds.
	// Why?
	
	// Actually, `reps()` I saw earlier was just `return 0`.
	// So it effectively disables repetition check.
	// This explains WHY we have so many repetitions.
	
	return 0
}

fn (m Move) is_same(other Move) bool {
	return m.from == other.from && m.to == other.to && m.bits == other.bits && m.promote == other.promote
}
