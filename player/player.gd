class_name PlayerFPSController extends CharacterBody3D

@onready var _camera: Camera3D = %Camera3D
@onready var _camera_start_value = _camera.position.x
@onready var _neck: Node3D = %Neck
@onready var _neck_start_height : float = _neck.position.y
@onready var _neck_start_z_value : float = _neck.position.z
@onready var _hurtbox_3d: Hurtbox3D = %Hurtbox3D
@onready var _hitbox_3d: Hitbox3D = %Hitbox3D
@onready var _interaction_ray_cast_3d: InteractionRayCast3D = $Neck/Camera3D/InteractionRayCast3D


@onready var _animation_player: AnimationPlayer = $AnimationPlayer

@export_range(0.001, 1.0) var mouse_sensitivity := 0.005

@export_category("Ground movement")
@export_range(1.0, 10.0, 0.1) var max_speed_jog := 4.0
@export_range(1.0, 15.0, 0.1) var max_speed_sprint := 7.0
@export_range(1.0, 100.0, 0.1) var acceleration_jog := 15.0
@export_range(1.0, 100.0, 0.1) var acceleration_sprint := 25.0
@export_range(1.0, 100.0, 0.1) var deceleration := 12.0

@export_category("Air movement")
@export_range(1.0, 50.0, 0.1) var gravity := 17.0
@export_range(1.0, 50.0, 0.1) var max_fall_speed := 20.0
@export_range(1.0, 20.0, 0.1) var jump_velocity := 8.0

@export var max_health := 10
@export var health := max_health : set = set_health

@export var max_stamina := 350
@export var stamina := max_stamina : set = set_stamina
var can_sprint := true

func set_stamina(new_stamina: int) -> void:
	stamina = clampi(new_stamina, 0, max_stamina)
	if new_stamina < max_stamina and new_stamina > 0:
		$StaminaTimer.start(0.0)
	if new_stamina <= 0:
		can_sprint = false

var is_inside_home : bool

var inventory := {
	"DoorBombE" : 500,
	"Nailboard" : 500,
	"BearTrap" : 500,
	"DoorTorchM" : 500,
	"GlueTrap" : 500,
	"SpeakerLure" : 500
	,
}

func set_health(new_health: int) -> void:
	health = clampi(new_health, 0, max_health)
	if new_health <= 0:
		print("game over via player death")

var last_damage_type = null


# Equip/Unequip Fists
var fists_up := false
# Equip/Unequip Hammer
var hammer_up := false

# Crouching
var is_crouching := false: set = set_is_crouching
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D
@onready var _collision_shape_start_height : float = _collision_shape.shape.height
@onready var _crouch_ceiling_cast: ShapeCast3D = %CrouchCeilingCast
@onready var _trap_visual_position: Marker3D = $Neck/Camera3D/TrapVisualPosition


@export_range(1.0, 10.0, 0.1) var max_speed_crouch := 2.0

@export var money := 750

var health_score : int = 0
var damage_just_taken := false

func set_is_crouching(new_value: bool) -> void:
	if is_crouching == new_value:
		return
	
	if new_value == false:
		_crouch_ceiling_cast.force_shapecast_update()
		if _crouch_ceiling_cast.is_colliding():
			return
	
	is_crouching = new_value
	
	if is_crouching:
		_collision_shape.shape.height = _collision_shape_start_height / 2.0
	else:
		_collision_shape.shape.height = _collision_shape_start_height
	_collision_shape.position.y = _collision_shape.shape.height / 2.0
	
	var target_neck_height := 0.0
	if is_crouching:
		target_neck_height = _neck_start_height * 0.5
	else:
		target_neck_height = _neck_start_height
	var crouch_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	crouch_tween.tween_property(_neck, "position:y", target_neck_height, 0.25)

# Used for the UI
var selected_trap = null
var selected_fixed_trap = null


## Handles camera rotation based on 2D input vector.
func _rotate_camera_by(look_offset_2d: Vector2) -> void:
	_camera.rotation.y -= look_offset_2d.x
	_camera.rotation.x -= look_offset_2d.y
	_camera.rotation.y = wrapf(_camera.rotation.y, -PI, PI)
	const MAX_VERTICAL_ANGLE := PI / 3.0
	_camera.rotation.x = clampf(_camera.rotation.x, -1.0 * MAX_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE )
	_camera.orthonormalize()

func _unhandled_input(event: InputEvent) -> void:
	#var vis := true
	#if event.is_action_pressed("confirm"):
		#set_collision_layer_value(1, not vis)
	
	
	var is_mouse_button := event is InputEventMouseButton
	var is_mouse_captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var is_escape_pressed := event.is_action_pressed("ui_cancel")
	
	if is_mouse_button and not is_mouse_captured:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif is_escape_pressed and is_mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if (event is InputEventMouseMotion and 
	Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		var look_offset_2d: Vector2 = event.screen_relative * mouse_sensitivity
		if damage_just_taken == false:
			_rotate_camera_by(look_offset_2d)


func _process(_delta: float) -> void:
	#print(selected_fixed_trap)
	#print(inventory)
	if Globals.main_level.current_stage > 0:
		selected_trap = null
		selected_fixed_trap = null

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("invis"):
		set_collision_layer_value(1, false)
	
	Trap3D.Blackboard.player_money = money
	
	var input_direction_2d := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var movement_direction_2d := input_direction_2d.rotated(-1.0 * _camera.rotation.y)
	var movement_direction_3d := Vector3(movement_direction_2d.x, 0.0, movement_direction_2d.y)
	
	var player_wants_to_move := movement_direction_2d.length() > 0.1
	# The player should come to a crawl if the camera damage tween is in effect
	#if not $CameraControlCooldownTimer.is_stopped():
		#var velocity_ground_plane := Vector3(velocity.x, 0.0, velocity.z)
		#velocity_ground_plane = velocity_ground_plane.move_toward(Vector3.ZERO, deceleration * delta)
		#velocity.x = velocity_ground_plane.x
		#velocity.z = velocity_ground_plane.z
	if player_wants_to_move:
		if $CameraControlCooldownTimer.is_stopped():
			var max_speed := max_speed_jog
			var acceleration := acceleration_jog
			if Input.is_action_pressed("sprint") and can_sprint == true:
				max_speed = max_speed_sprint
				acceleration = acceleration_sprint
				stamina -= 1 * delta
			if is_crouching:
				max_speed = max_speed_crouch
			var velocity_ground_plane := Vector3(velocity.x, 0.0, velocity.z)
			var velocity_change := acceleration * delta
			velocity_ground_plane = velocity_ground_plane.move_toward(
				movement_direction_3d * max_speed, velocity_change
			)
			velocity.x = velocity_ground_plane.x
			velocity.z = velocity_ground_plane.z
		elif not $CameraControlCooldownTimer.is_stopped():
			if is_instance_valid(last_damage_type):
				var velocity_ground_plane := Vector3(velocity.x, 0.0, velocity.z)
				velocity_ground_plane = velocity_ground_plane.move_toward(Vector3.ZERO, deceleration * delta)
				velocity.x = velocity_ground_plane.x
				velocity.z = velocity_ground_plane.z
	else:
		var velocity_ground_plane := Vector3(velocity.x, 0.0, velocity.z)
		velocity_ground_plane = velocity_ground_plane.move_toward(Vector3.ZERO, deceleration * delta)
		velocity.x = velocity_ground_plane.x
		velocity.z = velocity_ground_plane.z
	
	# Footstep noises
	if Input.is_action_pressed("sprint") and can_sprint == true:
		$FootStepsTimer.wait_time = 0.25
	else:
		$FootStepsTimer.wait_time = 0.5
	
	if velocity.length() > 0.5 and $FootStepsTimer.is_stopped() and is_on_floor() and not is_crouching:
		$FootStepsTimer.start()
	elif velocity.length() < 0.5 or is_equal_approx(velocity.length(), 0.1):
		
		$FootstepSounds.stop()
	
	# Crouching
	if is_on_floor():
		set_is_crouching(Input.is_action_pressed("crouch"))
	
	# Application of gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -max_fall_speed)
	# Player's 'y' velocity is set to a positive value when the player is touching the ground and pressing the jump input.
	if is_on_floor() and Input.is_action_just_pressed("jump") and not is_crouching:
		velocity.y = jump_velocity
		stamina -= 10 * delta
	
	var was_in_air := not is_on_floor()
	var fall_speed := absf(velocity.y)
	
	move_and_slide()
	
	var just_landed := was_in_air and is_on_floor()
	
	if just_landed:
		$FootstepSounds.play()
		var impact_intensity := fall_speed / max_fall_speed
		
		var impact_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		impact_tween.tween_property(_neck, "position:y", _neck.position.y - 0.2 * impact_intensity, 0.06)
		impact_tween.tween_property(_neck, "position:y", _neck_start_height, 0.1)
	
	# Attacking
	
	# Hides fists
	if fists_up == false:
		$Neck/Camera3D/Arms/LeftArm.hide()
		$Neck/Camera3D/Arms/RightArm.hide()
	else:
		$Neck/Camera3D/Arms/LeftArm.show()
		$Neck/Camera3D/Arms/RightArm.show()
	
	# Hides hammer
	if hammer_up == false:
		$Neck/Camera3D/Arms/Hammer.hide()
	else:
		$Neck/Camera3D/Arms/Hammer.show()
		$Neck/Camera3D/Arms/LeftArm.hide()
		$Neck/Camera3D/Arms/RightArm.hide()
		
	var trap_visual = $Neck/Camera3D/TrapVisualPosition.get_child(0)
	if trap_visual is Area3D:
		if Globals.main_level.current_stage > 0:
			trap_visual.queue_free()
		selected_trap = trap_visual.trap_name
		selected_fixed_trap = null
		#print("selected_trap is " + str(selected_trap))
	elif trap_visual is Node3D or selected_fixed_trap != null:
		selected_trap = null
	
	
	if (Input.is_action_just_pressed("equip_fists") or Input.is_action_just_pressed("trap_menu") ) and trap_visual != $Neck/Camera3D/TrapVisualPosition/DoNotRemove:
		trap_visual.queue_free()
	
	# Equips fists
	if Input.is_action_just_pressed("equip_fists"):
		await get_tree().create_timer(0.5).timeout
		fists_up = not fists_up 
		hammer_up = false
	
	
	if Input.is_action_just_pressed("trap_menu") and fists_up == true:
		fists_up = false
	
	# Equips hammer
	if Input.is_action_just_pressed("equip_hammer"):
		await get_tree().create_timer(0.5).timeout
		hammer_up = not hammer_up
		fists_up = false

	
	# Disables hitbox detection both ways if player isn't attacking
	if not _animation_player.is_playing():
		$Neck/Camera3D/Arms/Hitbox3D/CollisionShape3D.disabled = true
	elif _animation_player.is_playing():
		$Neck/Camera3D/Arms/Hitbox3D/CollisionShape3D.disabled = false
	
	if Input.is_action_just_pressed("attack") and fists_up == true:
		# Animate arms going forward
		var possible_anims := ["left_punch", "right_punch"]
		var random_anim = possible_anims.pick_random()
		var _previous_anim : String
		
		if _animation_player.is_playing():
			return
		_animation_player.play(random_anim)
		
		# Adjust hitbox position 
		pass
		
	if Input.is_action_just_pressed("interact") and hammer_up == true:
		# Animate hammer
		if _animation_player.is_playing():
			return
		_animation_player.play("hammer_swing")
	
	# Camera Damage Tween
	_hurtbox_3d.took_hit.connect(func _on_hurt_box_took_hit(_hit_box: Hitbox3D) -> void:
		last_damage_type = _hit_box.get_owner()
		#print(last_damage_type)
		if $DamageVisualTimer.is_stopped():
			damage_just_taken = true
			var damage_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var default_pos : Vector3 = Vector3(0.0, 0.0, 0.0)
			#var target_pos : Vector3 = Vector3(-0.5, 0.0, 0.0)
			var target_pos : Vector3 
			if _camera.rotation.y > -0.5 and _camera.rotation.y < 0.5:
				target_pos = Vector3(0.0, 0.0, randf_range(0.0, 0.4))
			elif _camera.rotation.y < 0.0 and _camera.rotation.y > -2.5:
				target_pos = Vector3(-randf_range(0.0, 0.4), 0.0, 0.0)
			elif _camera.rotation.y < -2.5 and _camera.rotation.y > -3.5:
				target_pos = Vector3(0.0, 0.0, -randf_range(0.0, 0.4))
			elif _camera.rotation.y > 2.0 and _camera.rotation.y < 3:
				target_pos = Vector3(0.0, 0.0, -randf_range(0.0, 0.4))
			elif _camera.rotation.y > 0.0 and _camera.rotation.y < 2.5:
				target_pos = Vector3(randf_range(0.0, 0.4), 0.0, 0.0)
			
			var rotation_range := randf_range(PI / 12, PI / 6)
			
			damage_tween.set_parallel(true)
			damage_tween.tween_property(_camera, "position", target_pos, 0.2)
			damage_tween.tween_property(_camera, "rotation:x", rotation_range, 0.2)
			damage_tween.tween_property(_camera, "rotation:z", 0.0, 0.2)
			
			damage_tween.chain()
			
			damage_tween.tween_property(_camera, "position", default_pos, 1.0)
			damage_tween.tween_property(_camera, "rotation:x", 0.0, 1.0)
			damage_tween.tween_property(_camera, "rotation:z", 0.0, 1.0)
			
			$DamageVisualTimer.start()
			$CameraControlCooldownTimer.start()
	)
func _ready() -> void:
	Globals.player = self
	$CameraControlCooldownTimer.timeout.connect(func() -> void:
		damage_just_taken = false
		)
	_hurtbox_3d.took_hit.connect(func _on_hurt_box_took_hit(_hit_box: Hitbox3D) -> void:
		stamina -= 25
		max_speed_sprint = clampf(max_speed_sprint, 4.5, 7.0)
		max_speed_sprint -= 0.25
		health -= _hit_box.damage
		health_score += 1
		print(health)
		print("max_speed_sprint is " + str(max_speed_sprint))
		print("took damage")
		)
	_hitbox_3d.hit_hurt_box.connect(func _on_hit(_hurt_box: Hurtbox3D) -> void:
		stamina -= 50
		var audio := AudioStreamPlayer3D.new()
		audio.stream = preload("res://weapons/sfx/275153__bird_man__punch.wav")
		if _hurt_box.hurtbox_type == 2:
			add_sibling(audio)
			audio.play()
			audio.finished.connect(audio.queue_free)
		)
	$FootStepsTimer.timeout.connect(func() -> void:
		$FootstepSounds.play()
		)
	$Neck/Camera3D/InteractionRayCast3D.hammer_interact.connect(func() -> void:
		if hammer_up == true:
			$Neck/Camera3D/InteractionRayCast3D._focused_node.interact()
		)
	
	$StaminaTimer.timeout.connect(func() -> void:
		if can_sprint == false and stamina == 0:
			can_sprint = true
			stamina = 350
		else:
			stamina = 350
		)
