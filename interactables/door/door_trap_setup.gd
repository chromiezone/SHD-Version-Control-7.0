extends FixedTrapVisual

func _ready() -> void:
	$TrapVisual.visible = true

func interact() -> void:
	super()
	if Globals.player.inventory["DoorBombE"] >= 1 and $TrapVisual.visible == true and Globals.player.selected_fixed_trap == "DoorBombE":
		place_trap()
	

func _physics_process(_delta: float) -> void:
	if Globals.player.selected_fixed_trap != null:
		$TrapVisual.visible = true
	else:
		$TrapVisual.visible = false

func place_trap() -> void:
	Globals.player.inventory["DoorBombE"] -= 1
	var trap = preload("res://traps/DoorBombE.tscn").instantiate()
	trap.position = $TrapTargetPos.position
	trap.rotation.y = PI
	add_child(trap)
	
	
	$TrapVisual.visible = false
