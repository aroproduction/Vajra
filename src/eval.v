module main

// TSCP Evaluation Constants
const doubled_pawn_penalty   = 10
const isolated_pawn_penalty  = 20
const backwards_pawn_penalty = 8
const passed_pawn_bonus      = 20
const rook_semi_open_file_bonus = 10
const rook_open_file_bonus   = 15
const rook_on_seventh_bonus  = 20

// Passed pawn bonus by rank (more aggressive scaling for advanced pawns)
// Index 0 = 2nd rank, Index 5 = 7th rank
const passed_pawn_bonus_by_rank = [10, 20, 35, 60, 100, 180]!

const pawn_value   = 100
const knight_value = 300
const bishop_value = 300
const rook_value   = 500
const queen_value  = 900
const king_value   = 10000 

// Piece-Square Tables 
// White perspective
const pawn_pcsq = [
	  0,   0,   0,   0,   0,   0,   0,   0,
	  5,  10,  15,  20,  20,  15,  10,   5,
	  4,   8,  12,  16,  16,  12,   8,   4,
	  3,   6,   9,  12,  12,   9,   6,   3,
	  2,   4,   6,   8,   8,   6,   4,   2,
	  1,   2,   3, -10, -10,   3,   2,   1,
	  0,   0,   0, -40, -40,   0,   0,   0,
	  0,   0,   0,   0,   0,   0,   0,   0
]!

const knight_pcsq = [
	-10, -10, -10, -10, -10, -10, -10, -10,
	-10,   0,   0,   0,   0,   0,   0, -10,
	-10,   0,   5,   5,   5,   5,   0, -10,
	-10,   0,   5,  10,  10,   5,   0, -10,
	-10,   0,   5,  10,  10,   5,   0, -10,
	-10,   0,   5,   5,   5,   5,   0, -10,
	-10,   0,   0,   0,   0,   0,   0, -10,
	-10, -30, -10, -10, -10, -10, -30, -10
]!

const bishop_pcsq = [
	-10, -10, -10, -10, -10, -10, -10, -10,
	-10,   0,   0,   0,   0,   0,   0, -10,
	-10,   0,   5,   5,   5,   5,   0, -10,
	-10,   0,   5,  10,  10,   5,   0, -10,
	-10,   0,   5,  10,  10,   5,   0, -10,
	-10,   0,   5,   5,   5,   5,   0, -10,
	-10,   0,   0,   0,   0,   0,   0, -10,
	-10, -10, -20, -10, -10, -20, -10, -10
]!

const king_pcsq = [
	-40, -40, -40, -40, -40, -40, -40, -40,
	-40, -40, -40, -40, -40, -40, -40, -40,
	-40, -40, -40, -40, -40, -40, -40, -40,
	-40, -40, -40, -40, -40, -40, -40, -40,
	-40, -40, -40, -40, -40, -40, -40, -40,
	-40, -40, -40, -40, -40, -40, -40, -40,
	-20, -20, -20, -20, -20, -20, -20, -20,
	  0,  20,  40, -20,   0, -20,  40,  20
]!

const king_endgame_pcsq = [
	 0,  10,  20,  30,  30,  20,  10,   0,
	10,  20,  30,  40,  40,  30,  20,  10,
	20,  30,  40,  50,  50,  40,  30,  20,
	30,  40,  50,  60,  60,  50,  40,  30,
	30,  40,  50,  60,  60,  50,  40,  30,
	20,  30,  40,  50,  50,  40,  30,  20,
	10,  20,  30,  40,  40,  30,  20,  10,
	 0,  10,  20,  30,  30,  20,  10,   0
]!

const flip = [
	 56,  57,  58,  59,  60,  61,  62,  63,
	 48,  49,  50,  51,  52,  53,  54,  55,
	 40,  41,  42,  43,  44,  45,  46,  47,
	 32,  33,  34,  35,  36,  37,  38,  39,
	 24,  25,  26,  27,  28,  29,  30,  31,
	 16,  17,  18,  19,  20,  21,  22,  23,
	  8,   9,  10,  11,  12,  13,  14,  15,
	  0,   1,   2,   3,   4,   5,   6,   7
]!

// Helpers
@[inline]
fn row(sq int) int { return sq >> 3 }

@[inline]
fn col(sq int) int { return sq & 7 }

struct EvalData {
mut:
	pawn_rank [2][10]int
	piece_mat [2]int
	pawn_mat  [2]int
}

pub fn (b Board) eval() int {
	mut d := EvalData{}
	
	// Init pawn_rank
	for i in 0 .. 10 {
		d.pawn_rank[light][i] = 0
		d.pawn_rank[dark][i] = 7
	}
	
	// First pass: Material counting and pawn ranks
	for i in 0 .. 64 {
		if b.color[i] == empty { continue }
		
		color := b.color[i]
		piece := b.piece[i]
		
		if piece == pawn {
			d.pawn_mat[color] += pawn_value
			c := col(i) + 1 // 1..8
			r := row(i)
			if color == light {
				if d.pawn_rank[light][c] < r { d.pawn_rank[light][c] = r }
			} else {
				if d.pawn_rank[dark][c] > r { d.pawn_rank[dark][c] = r }
			}
		} else {
			// Don't include King in piece_mat for scaling logic
			match piece {
				knight { d.piece_mat[color] += knight_value }
				bishop { d.piece_mat[color] += bishop_value }
				rook   { d.piece_mat[color] += rook_value }
				queen  { d.piece_mat[color] += queen_value }
				else {}
			}
		}
	}
	
	mut score := [0, 0]
	score[light] = d.piece_mat[light] + d.pawn_mat[light]
	score[dark] = d.piece_mat[dark] + d.pawn_mat[dark]
	
	// Second pass: Positional scoring
	for i in 0 .. 64 {
		if b.color[i] == empty { continue }
		
		color := b.color[i]
		piece := b.piece[i]
		
		if color == light {
			match piece {
				pawn { score[light] += eval_light_pawn(d, i) }
				knight { score[light] += knight_pcsq[i] }
				bishop { score[light] += bishop_pcsq[i] }
				rook {
					c := col(i) + 1
					if d.pawn_rank[light][c] == 0 { // Open file (no own pawn)
						if d.pawn_rank[dark][c] == 7 { // Fully open
							score[light] += rook_open_file_bonus
						} else {
							score[light] += rook_semi_open_file_bonus
						}
					}
					if row(i) == 1 { // 7th rank (rank 7 for white is row 1)
						score[light] += rook_on_seventh_bonus
					}
				}
				king {
					if d.piece_mat[dark] <= 1200 {
						score[light] += king_endgame_pcsq[i]
					} else {
						score[light] += eval_light_king(d, i)
					}
				}
				else {}
			}
		} else {
			match piece {
				pawn { score[dark] += eval_dark_pawn(d, i) }
				knight { score[dark] += knight_pcsq[flip[i]] }
				bishop { score[dark] += bishop_pcsq[flip[i]] }
				rook {
					c := col(i) + 1
					if d.pawn_rank[dark][c] == 7 {
						if d.pawn_rank[light][c] == 0 {
							score[dark] += rook_open_file_bonus
						} else {
							score[dark] += rook_semi_open_file_bonus
						}
					}
					if row(i) == 6 { // 7th rank relative to black (row 6)
						score[dark] += rook_on_seventh_bonus
					}
				}
				king {
					if d.piece_mat[light] <= 1200 {
						score[dark] += king_endgame_pcsq[flip[i]]
					} else {
						score[dark] += eval_dark_king(d, i)
					}
				}
				else {}
			}
		}
	}
	
	if b.side == light {
		return score[light] - score[dark]
	}
	return score[dark] - score[light]
}

fn eval_light_pawn(d EvalData, sq int) int {
	mut r := 0
	f := col(sq) + 1
	row_idx := row(sq)
	
	r += pawn_pcsq[sq]
	
	// Doubled
	if d.pawn_rank[light][f] > row_idx {
		r -= doubled_pawn_penalty
	}
	
	// Isolated
	if d.pawn_rank[light][f-1] == 0 && d.pawn_rank[light][f+1] == 0 {
		r -= isolated_pawn_penalty
	} else if d.pawn_rank[light][f-1] < row_idx && d.pawn_rank[light][f+1] < row_idx {
		r -= backwards_pawn_penalty
	}
	
	// Passed
	if d.pawn_rank[dark][f-1] >= row_idx && d.pawn_rank[dark][f] >= row_idx && d.pawn_rank[dark][f+1] >= row_idx {
		// Use rank-based bonus: rank 2 (row 6) = index 0, rank 7 (row 1) = index 5
		rank_bonus_idx := 6 - row_idx // row 6->0, row 5->1, ..., row 1->5
		if rank_bonus_idx >= 0 && rank_bonus_idx < 6 {
			r += passed_pawn_bonus_by_rank[rank_bonus_idx]
		}
	}
	
	return r
}

fn eval_dark_pawn(d EvalData, sq int) int {
	mut r := 0
	f := col(sq) + 1
	row_idx := row(sq)
	
	r += pawn_pcsq[flip[sq]]
	
	// Doubled
	if d.pawn_rank[dark][f] < row_idx {
		r -= doubled_pawn_penalty
	}
	
	// Isolated
	if d.pawn_rank[dark][f-1] == 7 && d.pawn_rank[dark][f+1] == 7 {
		r -= isolated_pawn_penalty
	} else if d.pawn_rank[dark][f-1] > row_idx && d.pawn_rank[dark][f+1] > row_idx {
		r -= backwards_pawn_penalty
	}
	
	// Passed
	if d.pawn_rank[light][f-1] <= row_idx && d.pawn_rank[light][f] <= row_idx && d.pawn_rank[light][f+1] <= row_idx {
		// Use rank-based bonus: rank 7 (row 1) = index 0, rank 2 (row 6) = index 5
		rank_bonus_idx := row_idx - 1 // row 1->0, row 2->1, ..., row 6->5
		if rank_bonus_idx >= 0 && rank_bonus_idx < 6 {
			r += passed_pawn_bonus_by_rank[rank_bonus_idx]
		}
	}
	
	return r
}

fn eval_light_king(d EvalData, sq int) int {
	mut r := king_pcsq[sq]
	c := col(sq)
	
	if c < 3 {
		r += eval_lkp(d, 1)
		r += eval_lkp(d, 2)
		r += eval_lkp(d, 3) / 2
	} else if c > 4 {
		r += eval_lkp(d, 8)
		r += eval_lkp(d, 7)
		r += eval_lkp(d, 6) / 2
	} else {
		for i in c .. c + 3 {
			if d.pawn_rank[light][i+1] == 0 && d.pawn_rank[dark][i+1] == 7 {
				r -= 10
			}
		}
	}
	
	r *= d.piece_mat[dark]
	r /= 3100
	return r
}

fn eval_lkp(d EvalData, f int) int {
	mut r := 0
	rank_light := d.pawn_rank[light][f]
	
	if rank_light == 6 { } // Not moved
	else if rank_light == 5 { r -= 10 }
	else if rank_light == 0 { r -= 25 }
	else { r -= 20 }
	
	rank_dark := d.pawn_rank[dark][f]
	if rank_dark == 7 { r -= 15 }
	else if rank_dark == 5 { r -= 10 }
	else if rank_dark == 4 { r -= 5 }
	
	return r
}

fn eval_dark_king(d EvalData, sq int) int {
	mut r := king_pcsq[flip[sq]]
	c := col(sq)
	
	if c < 3 {
		r += eval_dkp(d, 1)
		r += eval_dkp(d, 2)
		r += eval_dkp(d, 3) / 2
	} else if c > 4 {
		r += eval_dkp(d, 8)
		r += eval_dkp(d, 7)
		r += eval_dkp(d, 6) / 2
	} else {
		for i in c .. c + 3 {
			if d.pawn_rank[light][i+1] == 0 && d.pawn_rank[dark][i+1] == 7 {
				r -= 10
			}
		}
	}
	
	r *= d.piece_mat[light]
	r /= 3100
	return r
}

fn eval_dkp(d EvalData, f int) int {
	mut r := 0
	rank_dark := d.pawn_rank[dark][f]
	
	if rank_dark == 1 { }
	else if rank_dark == 2 { r -= 10 }
	else if rank_dark == 7 { r -= 25 }
	else { r -= 20 }
	
	rank_light := d.pawn_rank[light][f]
	if rank_light == 0 { r -= 15 }
	else if rank_light == 2 { r -= 10 }
	else if rank_light == 3 { r -= 5 }
	
	return r
}
