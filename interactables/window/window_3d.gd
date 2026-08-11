@tool
class_name Window3D extends Interactable3D

var currently_occupied_area : String = ""
var _tween_window : Tween = null
@onready var _bottom_pane: Node3D = $WindowMesh/BottomPane
var pane_position_y : float
@onready var _reroaming_target = $EnteringArea/CollisionShape3D
var occupancy_slots : int = 0 : set = set_occupancy_slots
var priority_list : Array = []

# In any instance of a door or window, position1 should be on the *inside* of the home.

func set_occupancy_slots(new_value) -> void:
	if occupancy_slots == new_value:
		return
	occupancy_slots = new_value
	if occupancy_slots >= 3:
		$SustainedOccupancyTimer.start()


func interact() -> void:
	super()
	set_is_active(not is_active)

var is_active := false: set = set_is_active

func set_is_active(value: bool) -> void:
	is_active = value
	if is_zero_approx(pane_position_y):
		$Open.play()
	else:
		$Close.play()
	
	#$MeshInstance3D.visible = not is_active
	#$StaticBody3D/CollisionShape3D.disabled = is_active
	
	var end_value := 0.772 if is_active else 0.0
	if _tween_window != null:
		_tween_window.kill()
	_tween_window = create_tween()
	_tween_window.set_ease(Tween.EASE_OUT)
	_tween_window.set_trans(Tween.TRANS_CUBIC if is_active else Tween.TRANS_SINE)
	
	_tween_window.tween_property(_bottom_pane, "position:y", end_value, 0.5)
	_tween_window.finished.connect(func() -> void:
		)
	
	

func sustained_occupancy_timer_timeout() -> void:
	if occupancy_slots >= 3:
		if not priority_list.is_empty():
			for i in priority_list:
				if i is Enemy3D:
					i.call_deferred("set_collision_mask_value", 2, false)

func _ready() -> void:
	pane_position_y = _bottom_pane.position.y
	$SustainedOccupancyTimer.timeout.connect(sustained_occupancy_timer_timeout)
	#$WindowMesh/BottomPane/AnimatableBody3D.sync_to_physics = false
	
	$WindowMesh/BottomPane/WindowGlass1_001.set_surface_override_material(0,preload("res://materials/glass.tres"))
	$WindowMesh/TopPane/WindowGlass1.set_surface_override_material(0, preload("res://materials/glass.tres"))
	
	$OccupancyArea.body_entered.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			occupancy_slots += 1
			priority_list.append(body)
			var index = priority_list.find(body)
			#if index > 3:
				#body.call_deferred("set_collision_mask_value", 2, false)
		)
	$OccupancyArea.body_exited.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			priority_list.erase(body)
			occupancy_slots -= 1
			body.call_deferred("set_collision_mask_value", 2, true)
		)
	
	$ExitingArea.body_entered.connect(func(body: Node3D) -> void:
		currently_occupied_area = "$ExitingArea"
		if body is Enemy3D:
			print("body entered")
			body.current_entryway = self
			body.window_exit_anim_end_position = $EnteringArea/CollisionShape3D.global_position
			#if is_active == true:
				#$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
			if is_active == false:
				await get_tree().create_timer(0.5).timeout
			
			if is_zero_approx(pane_position_y):
				$Open.play()
			
			var end_value = 0.772
			if _tween_window != null:
				_tween_window.kill()
			_tween_window = create_tween()
			_tween_window.set_ease(Tween.EASE_IN_OUT)
			_tween_window.set_trans(Tween.TRANS_QUAD)
			
			_tween_window.tween_property(_bottom_pane, "position:y", end_value, 0.5)
			
			can_interact = false
			body.window_anim_end_position = $ExitingArea/CollisionShape3D.global_position
			get_tree().create_timer(5.0).timeout.connect(func() -> void:
				can_interact = true
				)
				
		)
	$EnteringArea.body_entered.connect(func(body: Node3D) -> void:
		
		currently_occupied_area = "$EnteringArea"
		if body is Enemy3D: #and is_active == false:
			#$MeshInstance3D.visible = false
			#$StaticBody3D/CollisionShape3D.set_deferred("disabled", true)
			#print("enemy preparing to enter")
			body.current_entryway = self
			body.window_anim_end_position = $ExitingArea/CollisionShape3D.global_position
			
			if is_active == false:
				await get_tree().create_timer(2.0).timeout
			
			if is_zero_approx(pane_position_y):
				$Open.play()
			
			var end_value = 0.772
			if _tween_window != null:
				_tween_window.kill()
			_tween_window = create_tween()
			_tween_window.set_ease(Tween.EASE_IN_OUT)
			_tween_window.set_trans(Tween.TRANS_QUAD)
			
			_tween_window.tween_property(_bottom_pane, "position:y", end_value, 0.5)
			
			can_interact = false
			if body != null:
				body.window_anim_end_position = $ExitingArea/CollisionShape3D.global_position
			else:
				can_interact = true
				return
			get_tree().create_timer(5.0).timeout.connect(func() -> void:
				can_interact = true
				)
		)
	
func _process(_delta: float) -> void:
	pane_position_y = _bottom_pane.position.y
