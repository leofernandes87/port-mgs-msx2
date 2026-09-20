# Read-only debugger captures at RenderRoom return; no RAM/ROM writes.
set renderer none
set throttle off
set sound_driver null
set save_settings_on_exit false
set root [file dirname [info script]]
set captured [dict create]
set pending [dict create]
proc dump_bytes {file device offset count} {
    global root
    set stream [open [file join $root $file] wb]
    puts -nonewline $stream [debug read_block $device $offset $count]
    close $stream
}
proc finish {} {
    global root captured
    set stream [open [file join $root finished.txt] w]
    puts $stream "captured_rooms [dict keys $captured]"
    close $stream
    exit
}
proc room_return {room} {
    global root captured pending
    if {[dict exists $captured $room]} {return}
    dict set captured $room true
    set prefix [format "room-%03d" $room]
    dump_bytes "$prefix-ram.bin" memory 0xc000 0x4000
    dump_bytes "$prefix-vram.bin" VRAM 0 0x10000
    dump_bytes "$prefix-palette.bin" {VDP palette} 0 32
    set stream [open [file join $root "$prefix-state.txt"] w]
    puts $stream "room [debug read memory 49456]"
    puts $stream "tileset [debug read memory 49495]"
    puts $stream "pc [reg PC]"
    puts $stream "vdp_busy [expr {[debug read {VDP status regs} 2] & 1}]"
    puts $stream "capture_point RenderRoom_return_before_DrawDoors"
    close $stream
    if {[debug read {VDP status regs} 2] & 1} {
        debug breakpoint create -address 0x4edb -once true -command [list settled $room]
    } else {
        settled $room
    }
}
proc settled {room} {
    global captured
    set prefix [format "room-%03d" $room]
    dump_bytes "$prefix-settled-vram.bin" VRAM 0 0x10000
    if {[dict size $captured] >= 4} {finish}
}
proc room_entry {} {
    global captured pending
    set room [debug read memory 49456]
    if {[dict exists $captured $room] || [dict exists $pending $room]} {return}
    dict set pending $room true
    set stack [reg SP]
    set target [expr {[debug read memory $stack] | ([debug read memory [expr {($stack + 1) & 65535}]] << 8)}]
    debug breakpoint create -address $target -once true -command [list room_return $room]
}
debug breakpoint create -address 0x4cf0 -command room_entry
after time 120 finish
after realtime 45 finish
