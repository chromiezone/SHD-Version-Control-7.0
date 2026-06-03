class_name CoverSwitch extends Interactable3D

@onready var _cover_hinge: Marker3D = $CoverHinge
var is_active := false: set = set_is_active
var _cover_tween : Tween = null
var _collision_shape_tween : Tween = null
@onready var _collision_shape_3d: CollisionShape3D = $CollisionShape3D

func interact() -> void:
	super()
	set_is_active(not is_active)

func set_is_active(new_value) -> void:
	is_active = new_value
	if is_active:
		print("cover open")
	else:
		print("cover closed")
	
	
	var end_value := (- 4.0 * PI / 9) if is_active else (0.0)
	if _cover_tween != null:
		_cover_tween.kill()
	
	_cover_tween = create_tween()
	_cover_tween.set_trans(Tween.TRANS_QUAD)
	_cover_tween.tween_property(_cover_hinge, "rotation:x", end_value, 0.50)
	
	var _collision_position_end_value := Vector3(0.011, 1.415, -0.293) if is_active else Vector3(0.011, 1.284, -0.154)
	var _collision_rotation_end_value := ( 4.0 * PI / 9) if is_active else (0.0)
	if _collision_shape_tween != null:
		_collision_shape_tween.kill()
	
	_collision_shape_tween = create_tween()
	_collision_shape_tween.set_parallel(true)
	_collision_shape_tween.set_trans(Tween.TRANS_QUAD)
	_collision_shape_tween.tween_property(_collision_shape_3d, "position", _collision_position_end_value, 0.50)
	_collision_shape_tween.tween_property(_collision_shape_3d, "rotation:x", _collision_rotation_end_value, 0.50)
	
