class_name Terminal extends Interactable3D

var is_active := false: set = set_is_active

func set_is_active(new_value) -> void:
	is_active = new_value
	if is_active == true:
		print("in buy menu")
	else:
		print("exited buy menu")

func interact() -> void:
	super()
	set_is_active(not is_active)
