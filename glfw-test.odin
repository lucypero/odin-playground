package main

import "vendor:glfw"

main :: proc() {
    assert(cast(bool)glfw.Init())
    monitor := glfw.GetPrimaryMonitor()
    mode := glfw.GetVideoMode(monitor)
    window := glfw.CreateWindow(100, 100, "test", nil, nil)
    assert(window != nil)
    glfw.SetWindowMonitor(window, monitor, 0, 0, mode.width, mode.height, mode.refresh_rate)
    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)
    for !glfw.WindowShouldClose(window) {
        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}
