#@tool
class_name Door3D extends Interactable3D

@export var is_left_hand_door := true
@onready var _reroaming_target = $ExitingArea/CollisionShape3D
@onready var _door_body = $Door/Swivel/AnimatableBody3D
@onready var _top_section_interactable: FixedTrapVisual = $TrapSetup/Interactable2
@onready var _mid_section_interactable: FixedTrapVisual = $TrapSetup/Interactable

var is_active := false: set = set_is_active
var door_open := false

var _tween_door : Tween = null
@onready var _swivel: CSGCylinder3D = $Door/Swivel
 
var broken := false : set = set_broken
var cause_of_break : int
enum causes {BURGLAR, TRAP}
var broken_sound_played := false

var swivel_rotation_was_at_zero := true

var occupancy_slots : int = 0 : set = set_occupancy_slots
var priority_list : Array = []

# In any instance of a door or window, position1 should be on the *inside* of the home.

func set_occupancy_slots(new_value) -> void:
	if occupancy_slots == new_value:
		return
	if occupancy_slots != new_value:
		$CloseTimer.start()
	occupancy_slots = new_value
	if occupancy_slots >= 3:
		$SustainedOccupancyTimer.start()

func sustained_occupancy_timer_timeout() -> void:
	if occupancy_slots >= 3:
		if not priority_list.is_empty():
			for i in priority_list:
				if i is Enemy3D:
					i.call_deferred("set_collision_mask_value", 2, false)


var hinge1_completion: int = 3
var hinge2_completion: int = 3
var hinge3_completion: int = 3

var fix_completion : int = 3 : set = set_fix_completion

var door_trap : DoorTrap = null
var door_has_trap := false : set = set_door_trap


func set_door_trap(new_value: bool) -> void:
	door_has_trap = new_value




func set_fix_completion(new_value) -> void:
	fix_completion = new_value
	if new_value == 3:
		fix_door()

func set_broken(new_value) -> void:
	broken = new_value
	if new_value == true:
		is_active = true
		get_tree().create_timer(0.25 if _swivel.rotation.y < 0 else 0.01).timeout.connect(door_break_tween)
		if broken_sound_played == false:
			get_tree().create_timer(0.50).timeout.connect(func() -> void:
				$DoorBreak.play()
				broken_sound_played = true
				)
		$Door/Swivel/AnimatableBody3D/CollisionShape3D.disabled = true
		fix_completion = 0
		hinge1_completion = 0
		hinge2_completion = 0
		hinge3_completion = 0
	


func fix_door() -> void:
	print("door fixed")
	broken = false
	var position_end_value : Vector3 = Vector3(0.0, 1.0, 0.36) if is_left_hand_door else Vector3(0.0,1.0,-0.471)
	var rotation_end_value : Vector3 = Vector3(0.0, 0.0, 0.0) if is_left_hand_door else Vector3(0.0, PI, 0.0)
	
	if _tween_door != null:
			_tween_door.kill()
	_tween_door = create_tween()
	_tween_door.set_ease(Tween.EASE_OUT)
	_tween_door.set_trans(Tween.TRANS_BOUNCE)
	_tween_door.set_parallel(true)
	
	_tween_door.tween_property(_swivel, "position", position_end_value, 1.0)
	_tween_door.tween_property(_swivel, "rotation", rotation_end_value, 1.0)
	
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		$Door/Swivel/AnimatableBody3D/CollisionShape3D.disabled = false
		)

# In any instance of a door or window, red should be on the *inside* of the home.



func _ready() -> void:
	$SustainedOccupancyTimer.timeout.connect(sustained_occupancy_timer_timeout)
	
	$OccupancyArea.body_entered.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			occupancy_slots += 1
			priority_list.append(body)
			var index = priority_list.find(body)
		)
	$OccupancyArea.body_exited.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			priority_list.erase(body)
			occupancy_slots -= 1
			body.call_deferred("set_collision_mask_value", 2, true)
		)
	
	$InteractTimer.timeout.connect(func() -> void:
		can_interact = true
		print("should reset can interact")
		)
	
	
	match is_left_hand_door:
		true:
			$FixSetup.position = Vector3(0.0,0.0,0.0)
			_swivel.position = Vector3(0.0,1.0,0.36)
			_swivel.rotation.y = 0.0
			$TrapSetup.position = Vector3(0.0,0.0,-0.092)
			$TrapSetup/Interactable.trap_rotation_property = 0.0
		false:
			$FixSetup.position = Vector3(0.0,0.0,-0.771)
			_swivel.position = Vector3(0.0,1.0,-0.471)
			$TrapSetup.position = Vector3(0.0,0.0,1.266)
			_swivel.rotation.y = PI
			$TrapSetup/Interactable.trap_rotation_property = PI
			$TrapSetup/Interactable2.trap_should_be_on_right = false
	
	
	
	$FixSetup/HingeInteractable1.connect("interacted_with_hammer", func() -> void:
		if broken:
			print("fixed")
			hinge1_completion += 1
			if hinge1_completion == 3:
				fix_completion += 1
		)
	$FixSetup/HingeInteractable2.connect("interacted_with_hammer", func() -> void:
		if broken:
			print("fixed")
			hinge2_completion += 1
			if hinge2_completion == 3:
				fix_completion += 1
		)
	$FixSetup/HingeInteractable3.connect("interacted_with_hammer", func() -> void:
		if broken:
			print("fixed")
			hinge3_completion += 1
			if hinge3_completion == 3:
				fix_completion += 1
		)
	
	
	# Exiting Tween
	$ExitingArea.body_entered.connect(func(body: Node3D) -> void:
		var accepted_states = [2,3, 14]
		if body is Enemy3D:
			body.current_entryway = self
			body.temp_entryway = self
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				body.temp_entryway = null
				)
		if body is Burglar:
			body.door_exit_anim_end_position = $ExitingTweenTargetPos/CollisionShape3D.global_position
		if body is Burglar and is_active == false and body.current_state in accepted_states:
			if body.door_interaction_cooldown_timer.time_left > 0.0:
				return
			var direction_to_door = global_transform.origin - body.global_transform.origin
			direction_to_door = direction_to_door.normalized()
			var target_forward = -body.global_transform.basis.z.normalized()
			var dot_product = target_forward.dot(direction_to_door)
			if body._roaming_ray_cast.get_collider() == self or dot_product > 0.800:
				print("door should open")
				if not broken:
					$DoorForce.play()
					body.door_exit_anim_end_position = $ExitingTweenTargetPos/CollisionShape3D.global_position
					var end_value := - PI / 2.0
					if _tween_door != null:
						_tween_door.kill()
					_tween_door = create_tween()
					_tween_door.set_ease(Tween.EASE_OUT)
					_tween_door.set_trans(Tween.TRANS_BOUNCE)
					
					_tween_door.tween_property(_swivel, "rotation:y", end_value, 0.5)
					_tween_door.finished.connect(func() -> void:
						broken = true
					)
		elif body is Enemy3D and is_active == false and body.current_state not in accepted_states:
			if body.door_interaction_cooldown_timer.time_left > 0.0:
				return
			body.door_interaction_cooldown_timer.start()
			print("enemy preparing to exit")
			if not broken:
				$DoorForce.play()
				body.door_exit_anim_end_position = $ExitingTweenTargetPos/CollisionShape3D.global_position
				var end_value := - PI / 2.0
				var dir = lerp_angle(_swivel.rotation.y, end_value, 1)
				if _tween_door != null:
					_tween_door.kill()
				_tween_door = create_tween()
				_tween_door.set_ease(Tween.EASE_OUT)
				_tween_door.set_trans(Tween.TRANS_BOUNCE)
				
				_tween_door.tween_property(_swivel, "rotation:y", dir, 0.5)
				_tween_door.finished.connect(func() -> void:
					broken = true
					)
		)
		# Entering Tween
	#_entering_area_recheck()
	$EnteringArea.body_entered.connect(func(body: Node3D) -> void:
		var accepted_states = [0,1,2,3,4,13,14]
		#if broken == true:
			#return
		if body is Enemy3D:
			body.current_entryway = self
		if body is Enemy3D and body.current_state in accepted_states:
			print("enemy preparing to enter")
			if door_open == false:
				$DoorFidget.play(0.0)
			can_interact = false
			$InteractTimer.start()
			body.door_anim_end_position = $EnteringTweenTargetPos/CollisionShape3D.global_position
			await get_tree().create_timer(body.door_open_duration).timeout
			if $DoorFidget.is_playing():
				$DoorFidget.stop()
			if is_active == false and broken == false and door_open == false and $InteractTimer.is_stopped():
				$DoorForce.play()
				var end_value := PI / 2.0
				
				
				if _tween_door != null:
					_tween_door.kill()
				_tween_door = create_tween()
				_tween_door.set_ease(Tween.EASE_OUT)
				_tween_door.set_trans(Tween.TRANS_BOUNCE)
				
				_tween_door.tween_property(_swivel, "rotation:y", end_value, 0.5)
				_tween_door.finished.connect(func() -> void:
					if broken == false:
						#can_interact = true
						$CloseTimer.start(0.0)
					)
		elif body is Enemy3D and body.current_state == 7:
			if body.door_interaction_cooldown_timer.time_left > 0.0 or broken == true:
				return
			body.door_interaction_cooldown_timer.start()
			$InteractTimer.start()
			can_interact = false
			#$DoorForce.play()
			var end_value := PI / 2.0
			if is_left_hand_door == true and _swivel.rotation.y < end_value:
				$DoorForce.play()
			elif is_left_hand_door == false and _swivel.rotation.y >= end_value + 0.1:
				$DoorForce.play()
			
			
			
			if _tween_door != null:
				_tween_door.kill()
			_tween_door = create_tween()
			_tween_door.set_ease(Tween.EASE_OUT)
			_tween_door.set_trans(Tween.TRANS_BOUNCE)
			
			_tween_door.tween_property(_swivel, "rotation:y", end_value, 0.5)
			_tween_door.finished.connect(func() -> void:
				if broken == false:
					#can_interact = true
					$CloseTimer.start(0.0)
				)
		)
	$CloseTimer.timeout.connect(_on_close_timer_timeout)
	


func door_break_tween() -> void:
		# Door Breaking Tween
	
	#var door_rotation_negative = _swivel.rotation.y < 0.1
	#var position_end_value : Vector3 = Vector3(0.64, 0.025, 1.458) if door_rotation_negative else Vector3(-0.192, 0.048, 1.613)
	#var rotation_end_value : Vector3 = Vector3(47 * PI / 1800.0, (-71.9 / 180.0) * PI, - PI / 2.0) if door_rotation_negative else Vector3(3.1 * PI / 180.0, 37 * PI / 72, 101 * PI / 200)
	
	var facing_inwards = _swivel.rotation.y > 0.1 if is_left_hand_door else _swivel.rotation.y < PI
	var position_end_value : Vector3
	var rotation_end_value : Vector3 
	
	
	if is_left_hand_door:
		position_end_value = Vector3(-0.192, 0.048, 1.613) if facing_inwards else Vector3(0.64, 0.025, 1.458)
		rotation_end_value = Vector3(3.1 * PI / 180.0, 37 * PI / 72, 101 * PI / 200) if facing_inwards else Vector3(47 * PI / 1800.0, (-71.9 / 180.0) * PI, - PI / 2.0)
	else:
		position_end_value = Vector3(-1.339, 0.087, -1.236) if facing_inwards else Vector3(1.131, 0.098, -1.067) #Vector3(1.353, 0.025, -1.25)
		rotation_end_value = Vector3(0.0, (199.0 * PI / 225.0), (-931.0 * PI / 1800.0)) if facing_inwards else Vector3(0.0, (17.0 * PI / 12.0), (12.0 * PI / 25))#Vector3(0, (-289.0 * PI / 360.0), (917.0 * PI / 1800.0))
		
	if _tween_door != null:
			_tween_door.kill()
	_tween_door = create_tween()
	_tween_door.set_ease(Tween.EASE_OUT)
	_tween_door.set_trans(Tween.TRANS_BOUNCE)
	_tween_door.set_parallel(true)
	
	_tween_door.tween_property(_swivel, "position", position_end_value, 1.0)
	_tween_door.tween_property(_swivel, "rotation", rotation_end_value, 1.0)
	can_interact = false
	$InteractTimer.start()
	_tween_door.finished.connect(func() -> void:
		#can_interact = true
		)

func trap_door_break_tween() -> void:
		# Door Breaking Tween
	
	var door_rotation_negative = _swivel.rotation.y < 0.1
	var position_end_value : Vector3 = Vector3(0.64, 0.025, 1.458) if door_rotation_negative else Vector3(-0.192, 0.048, 1.613)
	var rotation_end_value : Vector3 = Vector3(47 * PI / 1800.0, (-71.9 / 180.0) * PI, - PI / 2.0) if door_rotation_negative else Vector3(3.1 * PI / 180.0, 37 * PI / 72, 101 * PI / 200)
	
	if _tween_door != null:
			_tween_door.kill()
	_tween_door = create_tween()
	_tween_door.set_ease(Tween.EASE_OUT)
	_tween_door.set_trans(Tween.TRANS_BOUNCE)
	_tween_door.set_parallel(true)
	
	_tween_door.tween_property(_swivel, "position", position_end_value, 1.0 if door_rotation_negative else 0.85)
	_tween_door.tween_property(_swivel, "rotation", rotation_end_value, 1.0 if door_rotation_negative else 0.85)


func _entering_area_recheck() -> void:
	if broken == true:
		return
	var bodies = $EnteringArea.get_overlapping_bodies()
	if bodies.size() > 0:
		for body in bodies:
			if body is Enemy3D and body.current_state == 7:
				if body.door_interaction_cooldown_timer.time_left > 0.0:
					return
				body.door_interaction_cooldown_timer.start()
				$InteractTimer.start()
				can_interact = false
				#$DoorForce.play()
				var end_value := PI / 2.0
				if is_left_hand_door == true and _swivel.rotation.y < end_value:
					$DoorForce.play()
				elif is_left_hand_door == false and _swivel.rotation.y > end_value + 0.1:
					$DoorForce.play()
				
				if _tween_door != null:
					_tween_door.kill()
				_tween_door = create_tween()
				_tween_door.set_ease(Tween.EASE_OUT)
				_tween_door.set_trans(Tween.TRANS_BOUNCE)
				
				_tween_door.tween_property(_swivel, "rotation:y", end_value, 0.5)
				_tween_door.finished.connect(func() -> void:
					if broken == false:
						#can_interact = true
						$CloseTimer.start(0.0)
					)
func _exiting_area_recheck() -> void:
	#var accepted_states = [2,3, 14]
	var bodies = $ExitingArea.get_overlapping_bodies()
	if bodies.size() > 0:
		for body in bodies:
			if body is Enemy3D and body.current_state == 7:
				if body.door_interaction_cooldown_timer.time_left > 0.0:
					return
				body.door_interaction_cooldown_timer.start()
				$InteractTimer.start()
				can_interact = false
				print("enemy preparing to exit")
				if not broken:
					$DoorForce.play()
					body.door_exit_anim_end_position = $ExitingTweenTargetPos/CollisionShape3D.global_position
					var end_value := - PI / 2.0
					var dir = lerp_angle(_swivel.rotation.y, end_value, 1)
					if _tween_door != null:
						_tween_door.kill()
					_tween_door = create_tween()
					_tween_door.set_ease(Tween.EASE_OUT)
					_tween_door.set_trans(Tween.TRANS_BOUNCE)
					
					_tween_door.tween_property(_swivel, "rotation:y", dir, 0.5)
					_tween_door.finished.connect(func() -> void:
						broken = true
						)


func _process(_delta: float) -> void:
	#print(str(self) + "broken is " + str(broken))
	print(str(self) + "can_interact is " + str(can_interact))
	#print(str(_swivel.rotation.y) + str(is_left_hand_door) + "door open is" + str(door_open))
	if door_trap != null:
		door_trap.door_trap_in_effect.connect(func() -> void:
			broken = true
			)
	
	if _swivel.rotation.y == 0.0 and is_left_hand_door == true:
		door_open = false
	elif is_equal_approx(_swivel.rotation.y, PI) and is_left_hand_door == false:
		door_open = false
	else:
		door_open = true
	
	#if door_open == true:
		#_top_section_interactable.can_interact = false
	#else:
		#_top_section_interactable.can_interact = true
	
	if door_open == true:
		$TrapSetup/Interactable2.can_interact = false
		#print("shouldnt be able to place door trap")
	
	var current_rotation = _swivel.rotation.y
	var is_at_zero = is_equal_approx(current_rotation, 0.0) if is_left_hand_door else is_equal_approx(current_rotation, PI)
	if is_at_zero and not swivel_rotation_was_at_zero:
		$DoorClose.play()
	swivel_rotation_was_at_zero = is_at_zero
	
	# Tracks whether the door has a trap attached
	for child in _mid_section_interactable.get_children():
		if child is DoorTrap:
			door_has_trap = true
			door_trap = child
	
	for child in _top_section_interactable.get_children():
		if child is DoorTrap:
			$Door/Swivel/RopeAttachment.show()
		else:
			$Door/Swivel/RopeAttachment.hide()
	

func _physics_process(_delta: float) -> void:
	print(_swivel.rotation.y)
	if Trap3D.Blackboard.player_money > 500:
		_mid_section_interactable.can_interact = true
		_top_section_interactable.can_interact = true
	if not broken:
		_entering_area_recheck()
		_exiting_area_recheck()
	if $ExitingArea.has_overlapping_bodies():
		_exiting_area_recheck()
	

func _on_close_timer_timeout() -> void:
	if broken:
		return
	$DoorCreakIdle.play(0.0)
	print("close")
	var end_value := 0.0 if is_left_hand_door else PI
	if _tween_door != null:
		_tween_door.kill()
	_tween_door = create_tween()
	_tween_door.set_ease(Tween.EASE_OUT)
	_tween_door.set_trans(Tween.TRANS_EXPO)
	
	_tween_door.tween_property(_swivel, "rotation:y", end_value, 3.0)
	

func interact() -> void:
	super()
	$DoorLure.is_active = true
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		$DoorLure.is_active = false
		)
	set_is_active(not is_active)
	if is_active == true and not broken:
		$DoorOpen.play()
	if not $CloseTimer.is_stopped():
		$CloseTimer.stop()

func set_is_active(value: bool) -> void:
	is_active = value
	#_static_body_collision_shape_3d.disabled = is_active
	#print(is_active)
	
	var left_end_value := PI / 2.0 if is_active else 0.0
	var right_end_value := PI / 2.0 if is_active else PI
	if _tween_door != null:
		_tween_door.kill()
	if broken == true:
		return
	_tween_door = create_tween()
	_tween_door.set_ease(Tween.EASE_OUT)
	_tween_door.set_trans(Tween.TRANS_BACK if is_active else Tween.TRANS_BOUNCE)
	
	_tween_door.tween_property(_swivel, "rotation:y", left_end_value if is_left_hand_door else right_end_value, 1.0)
	_tween_door.finished.connect(func() -> void:
		)
