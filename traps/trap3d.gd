class_name Trap3D extends Area3D

enum Cruelty {
	HUMANE,
	JUSTIFIABLE,
	BARBARIC,
	SADISTIC
}

var cruelty_rating : Cruelty = Cruelty.HUMANE

## Traps with this property set to "true" bypass evasion checks
var instant_death := false
## Traps with this property set to "true" are dependent on a power source.
@export var electric_powered := false
## Do I even need to explain?
@export var price := 250
## The probability of a trap succeeding or being evaded by enemies.
var tamper_chance = randi_range(1, 100)

var trap_name : String
signal placed_trap(trap_name)

func _init() -> void:
	emit_signal("placed_trap")
	Globals.trap_count += 1


class Blackboard extends RefCounted:
	static var player_money := 0
