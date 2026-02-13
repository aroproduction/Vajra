module main

import os
import time

pub struct UCIOptions {
pub mut:
	debug bool
}

pub fn uci_loop() {
	mut b := new_board()
	// mut options := UCIOptions{}
	
	// Flush stdout immediately implies we should rely on println which V flushes usually.
	
	for {
		// Blocking read. 
		// TODO: In future, this should probably be in a separate thread 
		// so we can receive 'stop' while searching.
		// For now, search will block this loop, so we can't stop it easily 
		// without checking stdin inside search or using threads.
		// Since V makes spawning easy, we might do `spawn search(...)` later.
		
		line := os.get_line()
		if line == "" { 
			// Check for EOF? 
			// If get_line returns empty string consistently it might be EOF or just empty line.
			// V's os.get_line returns empty string on EOF.
			// Ideally check for EOF signal but here loop continues.
			// If piped input closes, we should exit.
			// Let's rely on "quit" command for now, but safer to break on repeated empty reads if non-interactive?
			continue 
		}
		
		cmd_line := line.trim_space()
		if cmd_line == "" { continue }
		
		parts := cmd_line.split(' ')
		if parts.len == 0 { continue }
		
		cmd := parts[0]
		
		match cmd {
			"quit" { break }
			"uci" {
				println("id name Vajra 2.0")
				println("id author GitHub Copilot")
				// println("option name Hash type spin default 64 min 1 max 1024")
				println("uciok")
			}
			"isready" { println("readyok") }
			"ucinewgame" {
				b.init_board()
				// Clear hash etc
			}
			"position" {
				parse_position(mut b, parts)
			}
			"go" {
				parse_go(mut b, parts)
			}
			"d" {
				b.print()
				println("Fen: ${b.get_fen()}")
				println("Key: ${b.hash_key()}") // To be implemented
				println("Eval: ${b.eval()}")
			}
			// Custom debug commands
			"perft" {
				// perft <depth>
				if parts.len > 1 {
					depth := parts[1].int()
					sw := time.new_stopwatch()
					nodes := b.perft(depth)
					elapsed_ms := sw.elapsed().milliseconds()
					println("Nodes: $nodes Time: ${elapsed_ms}ms")
				}
			}
			else {
				// Unknown command
			}
		}
	}
}

fn parse_position(mut b Board, parts []string) {
	if parts.len < 2 { return }
	
	mut move_idx := -1
	
	if parts[1] == "startpos" {
		b.init_board()
		if parts.len > 2 && parts[2] == "moves" {
			move_idx = 3
		}
	} else if parts[1] == "fen" {
		// handle "position fen ... moves ..."
		mut fen_parts := []string{}
		for i in 2 .. parts.len {
			if parts[i] == "moves" {
				move_idx = i + 1
				break
			}
			fen_parts << parts[i]
		}
		
		// Reconstruct literal FEN string
		fen := fen_parts.join(" ") 
		b.parse_fen(fen)
	}
	
	if move_idx != -1 && move_idx < parts.len {
		moves := parts[move_idx..]
		for m_str in moves {
			m := b.move_from_str(m_str)
			if m.from == 0 && m.to == 0 && m.bits == 0 {
				continue
			}
			b.make_move(m)
		}
	}
}

fn parse_go(mut b Board, parts []string) {
	// Parse limits (wtime, btime, winc, binc, depth, nodes, etc.)
	// For now, just simplistic
	
	mut depth := -1
	
	for i := 1; i < parts.len; i++ {
		match parts[i] {
			"depth" { if i+1 < parts.len { depth = parts[i+1].int() } }
			"perft" { 
				// go perft <depth>
				if i+1 < parts.len {
					d := parts[i+1].int()
					nodes := b.perft(d)
					println("Nodes: $nodes")
					return 
				}
			}
			else {}
		}
	}
	
	// Start Search
	// Check for time
	mut time_limit := 0 // Infinite
	// Parse wtime/btime
	if b.side == light {
		idx := index_of(parts, "wtime")
		if idx != -1 && idx+1 < parts.len {
			// Basic time management: time / 30
			t := parts[idx+1].int()
			time_limit = t / 30
		}
	} else {
		idx := index_of(parts, "btime")
		if idx != -1 && idx+1 < parts.len {
			t := parts[idx+1].int()
			time_limit = t / 30
		}
	}
	
	mut movetime_idx := index_of(parts, "movetime")
	if movetime_idx != -1 && movetime_idx+1 < parts.len {
		time_limit = parts[movetime_idx+1].int()
	}

	mut search := new_search()
	
	// Default depth if not specified
	if depth == -1 { 
		depth = 64 // Iterative deepening will stop on time
	} else {
		// Fixed depth, maybe disable time limit?
		// Usually if depth is specified, time is ignored or secondary.
		// Let's set time limit huge if depth is fixed?
		// No, user might say `go depth 5 wtime 10000`. Stop at depth 5 even if time left.
	}
	
	result := search.think(mut b, depth, time_limit)
	println("bestmove ${result.best_move}")
}

fn index_of(arr []string, val string) int {
	for i, v in arr {
		if v == val { return i }
	}
	return -1
}

// Helper to calculate polyglot or simple hash
pub fn (b Board) hash_key() u64 {
	return b.hash
}
