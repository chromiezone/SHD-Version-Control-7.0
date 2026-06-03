class_name HammerInteractable extends Interactable3D

var player : PlayerFPSController = null
var level : Node3D = null

signal interacted_with_hammer

func _ready() -> void:
	player = Globals.player
	level = Globals.main_level

func _process(_delta: float) -> void:
	level = Globals.main_level

func interact() -> void:
	if player.hammer_up == true and level.current_stage == 0 or level.current_stage == 2:
		emit_signal("interacted_with_hammer")
		
