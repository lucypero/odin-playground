/*

This is to show that you can't alt tab out of the full screen window.
it was fixed in raylib. now odin vendor needs to be updated.

https://github.com/raysan5/raylib/issues/3865

*/


package main

import rl "vendor:raylib"

main :: proc() {
    rl.InitWindow(100, 100, "test")
    rl.ToggleBorderlessWindowed()
    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.EndDrawing()
    }
}
