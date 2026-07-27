class_name Enemy3D extends CharacterBody3D

@export_category("Debugging")
@export var debug_label: Label3D = null

@export_category("Base Stats")
@export var max_health := 100

@export var health := max_health : set = set_health


var is_inside_home := false
var lure: Lure3D = null

signal enemy_died

# Used for calculating player's score.
#var melee_cruelty : int = 0
var cruelty : int = 0

func set_health(new_health: int) -> void:
	health = clampi(new_health, 0, max_health)
	if health <= 0:
		destroy()
	

func destroy() -> void:
	#queue_free()
	call_deferred("set_collision_layer_value", 2, false)
	call_deferred("set_collision_mask_value", 2, false)
	get_tree().create_timer(5.0).timeout.connect(queue_free)
	enemy_died.emit()

var door_anim_end_position = null
var window_anim_end_position = null
var door_exit_anim_end_position = null
var window_exit_anim_end_position = null
var is_looting := false

class Blackboard extends RefCounted:
	static var house_origin := Vector3.ZERO
	static var point_of_entries := []
	static var loot_objects := []
	static var extraction_points := []
