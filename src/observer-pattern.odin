/*

My attempt at the observer pattern
C# delegates are good for this.

https://gameprogrammingpatterns.com/observer.html

*/


package main

import "core:fmt"
import "core:mem"

// signals
notif :: struct {
    ent: ^Entity,
    the_notif: proc(^Entity, int)
}

Signal :: [dynamic]notif

emit_signal :: proc(signal: ^Signal, param: int) {
    for n in signal {
        n.the_notif(n.ent, param)
    }
}

subscribe_to_signal :: proc(signal: ^Signal, ent: ^Entity, callback: proc(^Entity, int)) {
    n := notif { ent, callback }
    append(signal, n)
}

// Entity (observer)

Entity :: struct {
    thing: int
}

// entity callback
on_cooked_waffles :: proc(ent: ^Entity, how_many: int) {
    fmt.println("cooked waffles! entity is counting ", ent.thing + how_many)
    ent.thing += how_many
}

// Thing (subject)

Thing :: struct {
    cooked_waffles_signal: Signal,
}

thing_try_cook :: proc(thing: ^Thing) {

    // cooking...

    // oh u cooked 2 waffles! emit signal
    emit_signal(&thing.cooked_waffles_signal, 2)
}

main :: proc() {

    thing := Thing{}
    ent := Entity{}

    alloc: mem.Allocator

    subscribe_to_signal(&thing.cooked_waffles_signal, &ent, on_cooked_waffles)
    thing_try_cook(&thing)
}
