# Read-only probe: VDP interrupt rate versus game iterations on the profile machine.
# InterruptTick (Banks0123.asm:440-471), installed on H_TIMI (0xFD9F, Banks0123.asm:599-601), runs
# GameStatusLogic once per VDP interrupt unless TickInProgress (0xC005) shows the previous iteration
# still running; GameStatusLogic increments TickCounter (0xC003; Banks0123.asm:10058-10060), its
# only writer. Counts are keyed by GameStatus.GameMode (0xC000, 0xC151); "gaps" is the histogram of
# VDP interrupts between consecutive iterations. No RAM/VRAM/ROM writes and no key presses.
set renderer none
set throttle off
set sound_driver null
set save_settings_on_exit false
set root [file dirname [info script]]

set warmup 2
set window 120
set counting 0
set since_last 0
array set interrupts {}
array set ticks {}
array set gaps {}

proc state_key {} { return "[peek 0xC000].[peek 0xC151]" }
proc bump {name key} {
    upvar #0 $name counter
    if {![info exists counter($key)]} {set counter($key) 0}
    incr counter($key)
}

debug set_bp 0xFD9F {} {
    incr ::since_last
    if {$::counting} {bump ::interrupts [state_key]}
}
debug set_watchpoint write_mem 0xC003 {} {
    if {$::counting} {
        set key [state_key]
        bump ::ticks $key
        bump ::gaps "$key:$::since_last"
    }
    set ::since_last 0
}

after time $warmup {set ::counting 1}
after time [expr {$warmup + $window}] {
    set ::counting 0
    set stream [open [file join $::root tick_rate.txt] w]
    puts $stream "window_seconds $::window"
    puts $stream "vdp_r9 [vdpreg 9]"
    foreach key [lsort [array names ::interrupts]] {
        set t [expr {[info exists ::ticks($key)] ? $::ticks($key) : 0}]
        puts $stream "state $key interrupts $::interrupts($key) game_iterations $t"
    }
    foreach key [lsort [array names ::gaps]] {
        puts $stream "gap $key count $::gaps($key)"
    }
    close $stream
    exit
}
