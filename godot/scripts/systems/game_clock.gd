class_name GameClock
extends RefCounted

## Single time base for gameplay.
## InterruptTick (Banks0123.asm:440-471, hooked on H_TIMI at 599-601) runs GameStatusLogic once per
## VDP interrupt and skips the interrupt while TickInProgress shows the previous iteration still
## running; GameStatusLogic increments TickCounter (Banks0123.asm:10058-10060). There is no explicit
## wait in the code: the cadence comes from how long each iteration takes.
## openMSX probe (tools/emulation/tick_rate.tcl, C-BIOS_MSX2_EU): VDP R#9 = 82h (PAL, 50 Hz); in play
## (GameMode 0) one iteration every 2 interrupts, in the text window (GameMode 0Ah) every interrupt.
## The port keeps that strategy with a 60 Hz interrupt (project decision; the European machine is 50 Hz).

const INTERRUPT_HZ: int = 60
## Ported counters convert ticks with X / 60.0, so each iteration advances exactly this much.
const TICK_DELTA: float = 1.0 / 60.0
const CADENCE_PLAYING: int = 2
const CADENCE_TEXT_BOX: int = 1
## Modes not measured yet (radio, menus, binoculars) run on every interrupt.
const CADENCE_UNMEASURED: int = 1

var tick_counter: int = 0       # TickCounter (8 bits)
var interrupt_count: int = 0
var _interrupts_since_iteration: int = 0

## One VDP interrupt; returns true when a game iteration runs on it.
func interrupt(cadence: int) -> bool:
	interrupt_count += 1
	_interrupts_since_iteration += 1
	if _interrupts_since_iteration < maxi(1, cadence):
		return false
	_interrupts_since_iteration = 0
	tick_counter = (tick_counter + 1) & 0xFF
	return true
