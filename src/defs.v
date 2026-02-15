module src

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

pub const a7 = 8
pub const b7 = 9
pub const c7 = 10
pub const d7 = 11
pub const e7 = 12
pub const f7 = 13
pub const g7 = 14
pub const h7 = 15

pub const a6 = 16
pub const b6 = 17
pub const c6 = 18
pub const d6 = 19
pub const e6 = 20
pub const f6 = 21
pub const g6 = 22
pub const h6 = 23

pub const a5 = 24
pub const b5 = 25
pub const c5 = 26
pub const d5 = 27
pub const e5 = 28
pub const f5 = 29
pub const g5 = 30
pub const h5 = 31

pub const a4 = 32
pub const b4 = 33
pub const c4 = 34
pub const d4 = 35
pub const e4 = 36
pub const f4 = 37
pub const g4 = 38
pub const h4 = 39

pub const a3 = 40
pub const b3 = 41
pub const c3 = 42
pub const d3 = 43
pub const e3 = 44
pub const f3 = 45
pub const g3 = 46
pub const h3 = 47

pub const a2 = 48
pub const b2 = 49
pub const c2 = 50
pub const d2 = 51
pub const e2 = 52
pub const f2 = 53
pub const g2 = 54
pub const h2 = 55

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
	hash    u64
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
