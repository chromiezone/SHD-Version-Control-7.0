extends Interactable3D

func _ready() -> void:
	visible = true
	can_interact = false
	pass

func interact() -> void:
	super()
	print("attempting to place trap")
	if visible == true:
		place_trap()
	

func place_trap() -> void:
	print("placed trap")
	
	var trap = preload("res://traps/DoorBombE.tscn").instantiate()
	trap.position = $TrapTargetPos.position
	trap.rotation.y = PI
	add_child(trap)
