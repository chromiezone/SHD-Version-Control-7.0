class_name Lure3D extends Trap3D

## Tracks whether burglar has been afflicted by lure as to not be used multiple times
var has_lured := false

var in_effect := false : set = set_in_effect

func set_in_effect(new_value: bool) -> void:
	if in_effect == new_value:
		return
	in_effect = new_value
	if in_effect == true:
		pass
		
