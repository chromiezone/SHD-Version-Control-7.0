class_name PowerSwitch extends Interactable3D

var is_active := true: set = set_is_active

var _switch_tween : Tween = null
@onready var _swivel: Marker3D = $Swivel
var power_on := true
@onready var _switch_hinge: Marker3D = $PowerSwitchMesh/SwitchHinge

func interact() -> void:
	super()
	set_is_active(not is_active)

func set_is_active(new_value) -> void:
	is_active = new_value
	if is_active == true:
		power_on = true
		print("there is power")
	else:
		power_on = false
		print("there is no power, how suspicious")
	$AudioStreamPlayer3D.play(0.09)
	
	
	var end_value := (- 2.0 * PI / 9.0) if is_active else (PI / 3.0)
	if _switch_tween != null:
		_switch_tween.kill()
	
	_switch_tween = create_tween()
	_switch_tween.set_trans(Tween.TRANS_LINEAR)
	_switch_tween.tween_property(_switch_hinge, "rotation:x", end_value, 0.10)


	
	
