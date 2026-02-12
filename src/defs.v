module main

// Colors
pub const light = 0
pub const dark  = 1

// Pieces
pub const pawn   = 0
pub const knight = 1
pub const bishop = 2
pub const rook   = 3
pub const queen  = 4
pub const king   = 5
pub const empty  = 6

// Squares (0 = a8, 63 = h1)
pub const a8 = 0
pub const b8 = 1
pub const c8 = 2
pub const d8 = 3
pub const e8 = 4
pub const f8 = 5
pub const g8 = 6
pub const h8 = 7

pub const a1 = 56
pub const b1 = 57
pub const c1 = 58
pub const d1 = 59
pub const e1 = 60
pub const f1 = 61
pub const g1 = 62
pub const h1 = 63

// Move bits
pub const m_capture = 1
pub const m_castle  = 2
pub const m_ep      = 4
pub const m_pawn_start = 8
pub const m_pawn    = 16
pub const m_promote = 32

// Limits
pub const max_ply = 64 // Increased from 32 for safety
pub const max_moves = 256

pub struct Move {
pub mut:
	from    int
	to      int
	promote int
	bits    int
	score   int
}

pub struct Hist {
pub mut:
	m       Move
	capture int
	castle  int
	ep      int
	fifty   int
	hash    int
}

pub fn (m Move) str() string {
	f := sq_str(m.from)
	t := sq_str(m.to)
	pro := if (m.bits & m_promote) != 0 {
		match m.promote {
			knight { "n" }
			bishop { "b" }
			rook { "r" }
			queen { "q" }
			else { "" }
		}
	} else { "" }
	return "${f}${t}${pro}"
}

pub fn sq_str(sq int) string {
	c := sq & 7
	r := 8 - (sq >> 3)
	col_char := u8(97 + c).ascii_str()
	row_char := u8(48 + r).ascii_str()
	return "${col_char}${row_char}"
}

pub fn str_to_sq(s string) int {
	if s.len < 2 { return -1 }
	c := int(s[0]) - 97
	r := 8 - (int(s[1]) - 48)
	return r * 8 + c
}
