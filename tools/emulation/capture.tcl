# Read-only debugger captures at LoadRoomTiles and RenderRoom return; no RAM/ROM writes.
set renderer none
set throttle off
set sound_driver null
set save_settings_on_exit false
set root [file dirname [info script]]

set capture_mode "demo"
if {[file exists [file join $root config.tcl]]} {
    source [file join $root config.tcl]
}

set captured [dict create]
set pending [dict create]
set prior_captured [dict create]

proc dump_bytes {file device offset count} {
    global root
    set stream [open [file join $root $file] wb]
    puts -nonewline $stream [debug read_block $device $offset $count]
    close $stream
}

proc finish {} {
    global root captured
    catch { keymatrixup 8 1 }
    catch { keymatrixup 8 16 }
    catch { keymatrixup 8 32 }
    catch { keymatrixup 8 128 }
    catch { keymatrixup 7 128 }
    set stream [open [file join $root finished.txt] w]
    puts $stream "captured_rooms [dict keys $captured]"
    close $stream
    exit
}

proc load_tiles_entry {} {
    global root prior_captured
    set room [debug read memory 49456]
    if {[dict exists $prior_captured $room]} {return}
    dict set prior_captured $room true
    set prefix [format "room-%03d" $room]
    dump_bytes "$prefix-prior-vram.bin" VRAM 0 0x10000
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
}

set doors_captured [dict create]

proc doors_entry {} {
    global doors_captured
    set room [debug read memory 49456]
    if {[dict exists $doors_captured $room]} {return}
    set stack [reg SP]
    set target [expr {[debug read memory $stack] | ([debug read memory [expr {($stack + 1) & 65535}]] << 8)}]
    debug breakpoint create -address $target -once true -command [list doors_return $room]
}

proc doors_return {room} {
    global doors_captured
    if {[dict exists $doors_captured $room]} {return}
    dict set doors_captured $room true
    if {[debug read {VDP status regs} 2] & 1} {
        debug breakpoint create -address 0x4edb -once true -command [list doors_settled $room]
    } else {
        doors_settled $room
    }
}

proc doors_settled {room} {
    global doors_captured capture_mode
    set prefix [format "room-%03d" $room]
    dump_bytes "$prefix-doors-vram.bin" VRAM 0 0x10000
    dump_bytes "$prefix-doors-ram.bin" memory 0xc000 0x4000
    if {$capture_mode eq "demo" && [dict size $doors_captured] >= 4} {
        finish
    }
    if {$capture_mode eq "gameplay" && $room == 240} {
        finish
    }
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

debug breakpoint create -address 0x4935 -command load_tiles_entry
debug breakpoint create -address 0x4cf0 -command room_entry
debug breakpoint create -address 0x775f -command doors_entry

# Gameplay navigation state machine (used when capture_mode is "gameplay")
set gp_state 0

proc gp_step {} {
    global gp_state capture_mode
    if {$capture_mode ne "gameplay"} {return}
    set status [debug read memory 0xC000]
    set mode [debug read memory 0xC151]
    set tw_status [debug read memory 0xCEF2]
    set ctrl [debug read memory 0xC180]
    set room [debug read memory 0xC130]
    set py [debug read memory 0xC182]
    set px [debug read memory 0xC184]

    # Logo skip
    if {$gp_state == 0 && $status == 0 && [machine_info time] > 2.0} {
        keymatrixdown 8 1
        set gp_state 1
        after time 0.1 { keymatrixup 8 1 }
    }
    # Menu start
    if {$gp_state == 1 && $status == 1} {
        keymatrixdown 8 1
        set gp_state 2
        after time 0.1 { keymatrixup 8 1 }
    }

    # Radio dialogue in Room 121
    if {$gp_state == 2 && $status == 5} {
        if {$mode == 10 && $tw_status == 3} {
            keymatrixdown 7 128
            after time 0.05 { keymatrixup 7 128 }
        }
        if {$mode == 0 && $ctrl == 0} {
            keymatrixdown 8 32
            set gp_state 3
        }
    }

    # State 3: in Room 121 walking UP to Room 0
    if {$gp_state == 3 && $room == 0} {
        keymatrixup 8 32
        set gp_state 4
    }

    # State 4: in Room 0, navigate around fence to Room 1
    if {$gp_state == 4} {
        if {$room == 0} {
            if {$py > 172 && $px < 170} {
                catch { keymatrixup 8 128 }; catch { keymatrixup 8 16 }
                keymatrixdown 8 32
            } elseif {$px < 200 && $py > 150} {
                catch { keymatrixup 8 32 }; catch { keymatrixup 8 16 }
                keymatrixdown 8 128
            } elseif {$py > 88 && $px >= 190} {
                catch { keymatrixup 8 128 }; catch { keymatrixup 8 16 }
                keymatrixdown 8 32
            } elseif {$py <= 88 && $px > 140 && $py > 40} {
                catch { keymatrixup 8 32 }; catch { keymatrixup 8 128 }
                keymatrixdown 8 16
            } else {
                catch { keymatrixup 8 16 }; catch { keymatrixup 8 128 }
                keymatrixdown 8 32
            }
        } elseif {$room == 1} {
            catch { keymatrixup 8 32 }; catch { keymatrixup 8 16 }; catch { keymatrixup 8 128 }
            set gp_state 5
        }
    }

    # State 5: in Room 1, walk RIGHT to col 25 (x=200) then UP to Room 2
    if {$gp_state == 5} {
        if {$room == 1} {
            if {$px < 200 && $py > 150} {
                catch { keymatrixup 8 32 }
                keymatrixdown 8 128
            } else {
                catch { keymatrixup 8 128 }
                keymatrixdown 8 32
            }
        } elseif {$room == 2} {
            catch { keymatrixup 8 32 }; catch { keymatrixup 8 128 }
            set gp_state 6
        }
    }

    # State 6: in Room 2, take left passage (col 9.5, px=76) to Room 3
    if {$gp_state == 6} {
        if {$room == 2} {
            if {$px > 76 && $py > 150} {
                catch { keymatrixup 8 32 }
                keymatrixdown 8 16
            } elseif {$py > 40 && $px <= 82} {
                catch { keymatrixup 8 16 }
                keymatrixdown 8 32
            } elseif {$px < 152 && $py <= 45} {
                catch { keymatrixup 8 32 }
                keymatrixdown 8 128
            } else {
                catch { keymatrixup 8 128 }
                keymatrixdown 8 32
            }
        } elseif {$room == 3} {
            catch { keymatrixup 8 32 }; catch { keymatrixup 8 16 }; catch { keymatrixup 8 128 }
            set gp_state 7
        }
    }

    # State 7: in Room 3, navigate around barrier to elevator door
    if {$gp_state == 7} {
        if {$room == 3} {
            if {$py > 140 && $px > 100} {
                catch { keymatrixup 8 16 }; catch { keymatrixup 8 128 }
                keymatrixdown 8 32
            } elseif {$px > 26 && $py > 80} {
                catch { keymatrixup 8 32 }
                keymatrixdown 8 16
            } elseif {$py > 40 && $px <= 32} {
                catch { keymatrixup 8 16 }
                keymatrixdown 8 32
            } elseif {$px < 108 && $py <= 45} {
                catch { keymatrixup 8 32 }
                keymatrixdown 8 128
            } else {
                catch { keymatrixup 8 128 }
                keymatrixdown 8 32
            }
        } elseif {$room == 240} {
            catch { keymatrixup 8 32 }; catch { keymatrixup 8 128 }; catch { keymatrixup 8 16 }
            set gp_state 8
        }
    }

    if {[machine_info time] < 90} {
        after time 0.05 gp_step
    }
}

if {$capture_mode eq "gameplay"} {
    after time 0.5 gp_step
}

after time 120 finish
after realtime 45 finish
