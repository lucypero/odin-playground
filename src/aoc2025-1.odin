package main

import "core:strconv"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math"

main :: proc() {
	
	the_input, ok := os.read_entire_file("aoc1.input")
	assert(ok)
	
	lines := strings.split_lines(string(the_input))
	
	part_one(lines)
	part_two(lines)
}

part_one :: proc (lines : []string) {
	
	// dial starts at 50
	cur_number : int = 50
	zero_hits : int
	
	for line in lines {
		// gettin number
		if len(line) == 0 do continue
		dial_turn, ok := strconv.parse_int(line[1:], 10)
		assert(ok)
		
		if line[0] == 'L' do dial_turn *= -1
		cur_number = turn_dial(cur_number, dial_turn)
		
		if cur_number == 0 {
			zero_hits += 1
		}
	}
	
	// right answer: 1055
	fmt.printfln("day 1 - part one answer: %v", zero_hits)
}

part_two :: proc(lines : []string) {
	
	// dial starts at 50
	cur_number : int = 50
	zero_hits : int
	
	for line in lines {
		// gettin number
		if len(line) == 0 do continue
		dial_turn, ok := strconv.parse_int(line[1:], 10)
		assert(ok)
		
		prev_number := cur_number
		if line[0] == 'L' do dial_turn *= -1
		
		// turning dial
		cur_number = turn_dial(cur_number, dial_turn)
		
		// counting zero hits
		zero_hits += math.abs(dial_turn) / 100
		after_number := prev_number + (dial_turn % 100)
		
		if prev_number != 0 && (after_number <= 0 || after_number > 99) {
			zero_hits += 1
		}
	}

	// right answer: 6386
	fmt.printfln("day 1 - part two answer: %v", zero_hits)
}

turn_dial :: proc(prev_numb, turn_by: int) -> int {
	return (prev_numb + turn_by) %% 100
}
