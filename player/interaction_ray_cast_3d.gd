class_name InteractionRayCast3D extends RayCast3D

signal hammer_interact

var _focused_node: Interactable3D = null

func _init() -> void:
	enabled = false
	
	collide_with_bodies = false
	collide_with_areas = true

func _unhandled_input(event: InputEvent) -> void:
	if _focused_node != null and event.is_action_pressed("interact") and _focused_node.can_interact == true:
		if _focused_node is HammerInteractable:
			hammer_interact.emit()
			print("checking if hammer is equipped before commencing operation")
			return
			
		_focused_node.interact()
	

func _physics_process(_delta: float) -> void:
	force_raycast_update()
	var collider := get_collider() as Interactable3D
	_focused_node = collider
