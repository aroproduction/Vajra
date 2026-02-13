module main

// Tables

// 120-square mailbox to 64-square conversion
pub const mailbox = [
	 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	 -1,  0,  1,  2,  3,  4,  5,  6,  7, -1,
	 -1,  8,  9, 10, 11, 12, 13, 14, 15, -1,
	 -1, 16, 17, 18, 19, 20, 21, 22, 23, -1,
	 -1, 24, 25, 26, 27, 28, 29, 30, 31, -1,
	 -1, 32, 33, 34, 35, 36, 37, 38, 39, -1,
	 -1, 40, 41, 42, 43, 44, 45, 46, 47, -1,
	 -1, 48, 49, 50, 51, 52, 53, 54, 55, -1,
	 -1, 56, 57, 58, 59, 60, 61, 62, 63, -1,
	 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	 -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
]!

// 64-square to 120-square mailbox conversion
pub const mailbox64 = [
	21, 22, 23, 24, 25, 26, 27, 28,
	31, 32, 33, 34, 35, 36, 37, 38,
	41, 42, 43, 44, 45, 46, 47, 48,
	51, 52, 53, 54, 55, 56, 57, 58,
	61, 62, 63, 64, 65, 66, 67, 68,
	71, 72, 73, 74, 75, 76, 77, 78,
	81, 82, 83, 84, 85, 86, 87, 88,
	91, 92, 93, 94, 95, 96, 97, 98
]!

// Slide piece?
pub const slide = [
	false, false, true, true, true, false
]! // P, N, B, R, Q, K (Empty not needed)

// Number of directions
pub const offsets_count = [
	0, 8, 4, 4, 8, 8
]!

// Directions (Flattened 7*8 = 56)
pub const offset = [
	0, 0, 0, 0, 0, 0, 0, 0, // Pawn
	-21, -19, -12, -8, 8, 12, 19, 21, // Knight
	-11, -9, 9, 11, 0, 0, 0, 0, // Bishop
	-10, -1, 1, 10, 0, 0, 0, 0, // Rook
	-11, -10, -9, -1, 1, 9, 10, 11, // Queen
	-11, -10, -9, -1, 1, 9, 10, 11, // King
	0, 0, 0, 0, 0, 0, 0, 0 // Empty
]!

// Castle mask
pub const castle_mask = [
	7, 15, 15, 15,  3, 15, 15, 11, // Rank 8 (0-7)
    15, 15, 15, 15, 15, 15, 15, 15, // Rank 7
    15, 15, 15, 15, 15, 15, 15, 15, // Rank 6
    15, 15, 15, 15, 15, 15, 15, 15, // Rank 5
    15, 15, 15, 15, 15, 15, 15, 15, // Rank 4
    15, 15, 15, 15, 15, 15, 15, 15, // Rank 3
    15, 15, 15, 15, 15, 15, 15, 15, // Rank 2
    13, 15, 15, 15, 12, 15, 15, 14  // Rank 1 (56-63)
]!

// Piece values (TSCP)
pub const piece_value = [ 100, 300, 300, 500, 900, 0, 0 ]!

// Piece chars
pub const piece_char = "pnbrqk"

// Zobrist random numbers for hashing
pub const hash_piece = init_hash_piece()
pub const hash_side = u64(0x3141592653589793)
pub const hash_ep = init_hash_ep()

fn init_hash_piece() [2][6][64]u64 {
	mut h := [2][6][64]u64{}
	mut seed := u64(0)
	for color in 0..2 {
		for piece in 0..6 {
			for sq in 0..64 {
				seed = xorshift64(seed)
				h[color][piece][sq] = seed
			}
		}
	}
	return h
}

fn init_hash_ep() [64]u64 {
	mut h := [64]u64{}
	mut seed := u64(0x123456789ABCDEF0)
	for i in 0..64 {
		seed = xorshift64(seed)
		h[i] = seed
	}
	return h
}

fn xorshift64(x u64) u64 {
	mut val := x
	if val == 0 { val = 0x123456789ABCDEF0 }
	val ^= val << 13
	val ^= val >> 7
	val ^= val << 17
	return val
}
