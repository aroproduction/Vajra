module src

// Transposition Table Entry Types
pub const tt_exact = 0   // Exact score (PV node)
pub const tt_alpha = 1   // Upper bound (fail-low)
pub const tt_beta  = 2   // Lower bound (fail-high, cut node)

pub struct TTEntry {
pub mut:
	hash   u64   // Zobrist hash key
	depth  i8    // Search depth
	flag   i8    // tt_exact, tt_alpha, or tt_beta
	score  i16   // Stored score
	best   Move  // Best move from this position
	age    i8    // Age for replacement scheme
}

pub struct TranspositionTable {
pub mut:
	table []TTEntry
	size  int
	age   i8
}

pub fn new_tt(size_mb int) TranspositionTable {
	// Calculate number of entries based on megabytes
	// Each entry is approximately: 8 (hash) + 1 (depth) + 1 (flag) + 2 (score) + 8 (move) + 1 (age) = ~21 bytes
	// For simplicity, use ~24 bytes per entry
	entries := (size_mb * 1024 * 1024) / 24
	
	return TranspositionTable{
		table: []TTEntry{len: entries}
		size: entries
		age: 0
	}
}

// Clear the transposition table
pub fn (mut tt TranspositionTable) clear() {
	for i in 0 .. tt.size {
		tt.table[i] = TTEntry{}
	}
	tt.age = 0
}

// Increment age (called at the start of each search)
pub fn (mut tt TranspositionTable) new_search() {
	tt.age++
	if tt.age > 100 {
		tt.age = 0
	}
}

// Probe the transposition table
pub fn (tt TranspositionTable) probe(hash u64) ?TTEntry {
	if tt.size == 0 {
		return none
	}
	
	index := int(hash % u64(tt.size))
	entry := tt.table[index]
	
	if entry.hash == hash {
		return entry
	}
	
	return none
}

// Store an entry in the transposition table
pub fn (mut tt TranspositionTable) store(hash u64, depth int, flag int, score int, best Move) {
	if tt.size == 0 {
		return
	}
	
	index := int(hash % u64(tt.size))
	
	// Replacement scheme: always replace if:
	// 1. Slot is empty (hash == 0)
	// 2. Same position (hash match)
	// 3. Deeper search
	// 4. Old entry (different age)
	
	existing := tt.table[index]
	
	should_replace := existing.hash == 0 
		|| existing.hash == hash 
		|| depth >= existing.depth
		|| tt.age != existing.age
	
	if should_replace {
		tt.table[index] = TTEntry{
			hash: hash
			depth: i8(depth)
			flag: i8(flag)
			score: i16(score)
			best: best
			age: tt.age
		}
	}
}

// Adjust mate scores when storing/retrieving from TT
// Mate scores are relative to the current ply, so we need to adjust them
pub fn (tt TranspositionTable) adjust_mate_score_from_tt(score int, ply int) int {
	if score > mate_score - 100 {
		return score - ply
	} else if score < -mate_score + 100 {
		return score + ply
	}
	return score
}

pub fn (tt TranspositionTable) adjust_mate_score_to_tt(score int, ply int) int {
	if score > mate_score - 100 {
		return score + ply
	} else if score < -mate_score + 100 {
		return score - ply
	}
	return score
}
