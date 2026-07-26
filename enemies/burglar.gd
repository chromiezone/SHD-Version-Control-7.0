class_name Burglar extends Enemy3D

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("confirm"):
		#var random_position := Vector3.ZERO
		#random_position.x = randf_range(-5.0, 5.0)
		#random_position.z = randf_range(-5.0, 5.0)
		#_navigation_agent_3d.set_target_position(random_position)

signal burglar_path_stop

@onready var burglar_skin: Node3D = $BurglarSkinV2


@onready var label_3d: Label3D = $Label3D
@onready var _hurtbox_3d: Hurtbox3D = %Hurtbox3D
@onready var _animation_player: AnimationPlayer = %AnimationPlayer

@onready var _roaming_ray_cast: RayCast3D = %RoamingRayCast
@onready var _obstacle_avoidance_raycasts: Node3D = %ObstacleAvoidanceRaycasts
@onready var _grounding_ray_cast: RayCast3D = $GroundingRayCast
@export var avoidance_strength := 1000.0
@onready var _navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@export_category("Movement")
@export_range(1.0, 50.0, 0.1) var gravity := 17.0
@export_range(1.0, 50.0, 0.1) var max_fall_speed := 20.0

var look_rotation_speed := 5.0



func calculate_avoidance_force() -> Vector3:
	var avoidance_force := Vector3.ZERO
	
	for raycast in _obstacle_avoidance_raycasts.get_children():
		if raycast.is_colliding():
			var collision_position = raycast.get_collision_point()
			var direction_away_from_obstacle = collision_position.direction_to(raycast.global_position)
			var ray_length = raycast.target_position.length()
			var intensity = 1.0 - collision_position.distance_to(raycast.global_position) / ray_length
			var force = direction_away_from_obstacle * avoidance_strength * intensity
			avoidance_force += force
	return avoidance_force

var player: CharacterBody3D = null
var player_out_of_sight_pos : Vector3 

var point_of_entry = null
var point_of_exit = null
var current_entryway = null : set = set_current_entryway
var temp_entryway = null
var current_entryway_just_updated : bool = false
var prioritized_burglar : Enemy3D = null
func set_current_entryway(new_entryway) -> void:
	if current_entryway == new_entryway:
		return
	current_entryway = new_entryway
	current_entryway_just_updated = true
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		current_entryway_just_updated = false
		)
var entryway_reference = null

var nearest_poxit = null

var nearest_loot_object : LootObject = null
var filtered_loot_objects : Array = []
@onready var looting_timer_node: Timer = $LootingTimer
var has_loot := false

var being_lured := false : set = set_being_lured
var velocity_is_stagnant := false


## For the duration of this timer, the burglar will not take into account more lures other
## than the one currently being visited.
@onready var _lure_interaction_cooldown: Timer = $LureInteractionCooldown
var lure_delta_timer := 0.0 : set = set_lure_delta_timer 
func set_lure_delta_timer(new_value) -> void:
	if lure_delta_timer == new_value:
		return
	lure_delta_timer = new_value
	if new_value >= 2.5:
		print("should exit lure")
		being_lured = false
		get_tree().create_timer(1.0).timeout.connect(set_current_state.bind(State.LOOTING))

func set_being_lured(new_value) -> void:
	if new_value == false and being_lured == true:
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			lure = null)
	
	being_lured = new_value
	if being_lured == true:
		
		_lure_interaction_cooldown.start()
	
	

# Combat variables
var near_relative_entry := false
var vision_target = null : set = set_vision_target
var vision_target_just_turned_player := false
var vision_target_just_turned_entry := false


func set_vision_target(new_value: Node3D) -> void:
	if vision_target == new_value:
		return
	vision_target = new_value
	if new_value:
		$VisionTargetChangeTimer.start()
	if new_value == player:
		vision_target_just_turned_player = true
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			vision_target_just_turned_player = false
			)
	elif new_value is Door3D or new_value is Window3D:
		vision_target_just_turned_entry = true
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			vision_target_just_turned_entry = false
			)

# Used for selecting the burglar's poxit
var chance = randi_range(1, 100)

# Used for determing burglar's successful evasion of trap damage
var evasion_chance : int

# Used for determing whether burglar will get stunned by a trap during the COMBAT state
# Updated everytime the combat state is entered.
var chance_to_stun = randf()

# Stored at the end of the roaming state and called upon if POE happens to be a window
# as otherwise, the burglar comes off the floor when moving towards the window.
var stored_y_position : float



@export var walk_speed := 2.0
@export var run_speed := 6.0
var walk_acceleration_factor = 5.0
var run_acceleration_factor = 7.5

var door_open_duration := 5.0
var window_open_duration := 5.0

var weapon_type = MeleeWeapon

var movement_states_array = [0, 1, 4]

var moving := false : set = set_moving
func set_moving(new_value) -> void:
	if moving != new_value:
		moving = new_value
	if not $Movement.is_playing():
		$Movement.play()
	if new_value == false:
		$Movement.stop()

var interacted_with_trap := [
	{"name": "DoorBombE", "times_interacted_with": 0},
	{"name": "Nailboard", "times_interacted_with": 0},
]

@onready var _footstep_detect: Area3D = $FootstepDetect
var footstep_area_occupied := false
var player_spotted := false : set = set_player_spotted
var player_spotted_just_true := false
var player_spotted_just_false := false

func set_player_spotted(new_value: bool) -> void:
	if player_spotted == new_value:
		return
	player_spotted = new_value
	
	if new_value == true:
		$AwarenessTimer.start()
		player_spotted_just_true = true
		get_tree().create_timer(0.75).timeout.connect(func() -> void:
			player_spotted_just_true = false
			)
	if new_value == false:
		player_out_of_sight_pos = player.global_position
		$AwarenessTimer.start()
		player_spotted_just_false = true
		get_tree().create_timer(0.75).timeout.connect(func() -> void:
			player_spotted_just_false = false
			)
	

@onready var door_interaction_cooldown_timer: Timer = $DoorInteractionCooldown


enum State {
	ROAMING, # Burglar spawns and loops around house until it spots point of entry.
	MOVING_TO_POE, # Burglar moves towards POE
	ENTERING, # Entering tween
	LOOTING, # Burglar moves from loot object to loot object
	MOVING_TO_POXIT, # Burglar moves to exit point
	EXITING, # Exiting tween
	EXTRACTION, # Burglar escapes to bounds of play area
	COMBAT,
	STRIKE,
	SHOOT, 
	STUNNED_BY_PLAYER,
	STUNNED_BY_TRAP,
	STRIKE_DELAY,
	REROAMING, # Burglar fought player, ended up outside, and is now returning inside to keep looting.
	MOVING_TO_LURE, # Burglar moves towards Lure trap
	WINDOW_WAIT,
}

var current_state: State = State.ROAMING:
	set = set_current_state

var last_state: int

func set_current_state(new_state: State) -> void:
	current_state = new_state
	
	
	
	match current_state:
		State.ROAMING:
			if is_inside_home == true:
				set_current_state(State.LOOTING)
		State.ENTERING:
			_roaming_ray_cast.target_position.z = -7.5
			if current_entryway != null:
				if current_entryway is Door3D:
					var door = current_entryway
					if door.is_active == false:
						await get_tree().create_timer(door_open_duration).timeout
					var entering_door_tween := create_tween()
					entering_door_tween.tween_property(self, "global_position", door_anim_end_position, 1.0)
					entering_door_tween.finished.connect(func() -> void:
						get_tree().create_timer(2.0).timeout.connect(set_current_state.bind(State.LOOTING))
					)
				elif current_entryway is Window3D:
					var window = current_entryway
					if window._bottom_pane.position.y == 0.0:
						await get_tree().create_timer(window_open_duration).timeout
					if not window.priority_list.is_empty():
						prioritized_burglar = window.priority_list[0]
					if self != prioritized_burglar:
						set_current_state(State.WINDOW_WAIT)
						return
					var entering_window_tween := create_tween().set_parallel(true)
					entering_window_tween.tween_property(self, "global_position:x", window_anim_end_position.x, 1.0)
					entering_window_tween.tween_property(self, "global_position:z", window_anim_end_position.z, 1.0)
					entering_window_tween.finished.connect(func() -> void:
						get_tree().create_timer(2.0).timeout.connect(set_current_state.bind(State.LOOTING))
					)
		State.EXITING:
			if current_entryway != null:
				if current_entryway is Door3D:
					var exiting_door_tween := create_tween()
					exiting_door_tween.tween_property(self, "global_position", door_exit_anim_end_position, 1.0)
					#exiting_door_tween.finished.connect(set_current_state.bind(State.EXTRACTION))
					exiting_door_tween.finished.connect(func() -> void:
						if last_state != 4:
							set_current_state(State.COMBAT)
						elif last_state == 4:
							set_current_state(State.EXTRACTION)
						)
				elif current_entryway is Window3D:
					var window = current_entryway
					if not window.priority_list.is_empty():
						prioritized_burglar = window.priority_list[0]
					if self != prioritized_burglar:
						set_current_state(State.WINDOW_WAIT)
						return
					var exiting_window_tween := create_tween().set_parallel(true)
					exiting_window_tween.tween_property(self, "global_position:x", window_exit_anim_end_position.x, 1.0)
					exiting_window_tween.tween_property(self, "global_position:z", window_exit_anim_end_position.z, 1.0)
					exiting_window_tween.finished.connect(func() -> void:
						if last_state != 4:
							set_current_state(State.COMBAT)
						elif last_state == 4:
							set_current_state(State.EXTRACTION)
					)
		State.LOOTING:
			if player_spotted == true or last_state == 7:
				set_current_state(State.COMBAT)
		State.COMBAT:
			being_lured = false
			vision_target = player
			chance_to_stun = randf()
			if $MeleeCooldown.is_connected("timeout", set_current_state.bind(State.COMBAT)):
				$MeleeCooldown.timeout.disconnect(set_current_state.bind(State.COMBAT))
				print("disconnected")
			if $ShootCooldown.is_connected("timeout", set_current_state.bind(State.COMBAT)):
				$ShootCooldown.timeout.disconnect(set_current_state.bind(State.COMBAT))
				print("disconnected")
		State.STRIKE:
			var strike_twice_chance = randi_range(1, 100)
			if strike_twice_chance <= 50:
				_animation_player.play("melee_attack")
			elif strike_twice_chance > 50:
				_animation_player.play("melee_attack")
				_animation_player.queue("melee_attack")
			$MeleeCooldown.start()
			if not $MeleeCooldown.is_connected("timeout", set_current_state.bind(State.COMBAT)):
				$MeleeCooldown.timeout.connect(set_current_state.bind(State.COMBAT))
			#_animation_player.animation_finished.connect(set_current_state.bind(State.COMBAT))
		State.SHOOT:
			$ShootCooldown.start()
			_animation_player.play("firing")
			if $VisionRayCast.get_collider() == player:
				player.health -= weapon_type.damage
			$ShootCooldown.timeout.connect(set_current_state.bind(State.COMBAT))
		State.STUNNED_BY_PLAYER:
			print("stunned")
			$BurglarSkinV2/AnimationPlayer.play("stun")
			get_tree().create_timer(2.0).timeout.connect(set_current_state.bind(State.COMBAT))
		State.STUNNED_BY_TRAP:
			$BurglarSkinV2/AnimationPlayer.play("stun")
			match last_state:
				3: # Looting State
					get_tree().create_timer(1.0).timeout.connect(set_current_state.bind(State.LOOTING))
				7: # Combat State
					get_tree().create_timer(1.0).timeout.connect(set_current_state.bind(State.COMBAT))
			if last_state not in [3,7] and $AwarenessTimer.time_left > 0.0:
				get_tree().create_timer(2.0).timeout.connect(set_current_state.bind(State.COMBAT))
		State.STRIKE_DELAY:
			get_tree().create_timer(randf_range(0.01,0.10)).timeout.connect(set_current_state.bind(State.STRIKE))
		State.MOVING_TO_LURE:
			velocity_is_stagnant = false
			lure_delta_timer = 0.0
		State.REROAMING:
			door_interaction_cooldown_timer.start()
		State.MOVING_TO_POXIT:
			if point_of_exit == null:
				point_of_exit = nearest_poxit

func _on_nav_agent_velocity_computed(safe_velocity) -> void:
	pass

func _ready() -> void:
	$NavigationAgent3D.velocity_computed.connect(_on_nav_agent_velocity_computed)
	
	
	_footstep_detect.body_entered.connect(func(body: Node3D) -> void:
		if body == player:
			footstep_area_occupied = true
		)
	_footstep_detect.body_exited.connect(func(body: Node3D) -> void:
		if body == player:
			footstep_area_occupied = false
		)
	_roaming_ray_cast.target_position.z = -50.0
	# Stores reference to player
	player = get_tree().root.get_node("TestScene/Player")
	debug_label.text = str(health)
	filtered_loot_objects = Blackboard.loot_objects
	weapon_type = $Arm/ArmBody/HandleMarker.get_child(0)
	set_moving(false)
	$MeleeHitbox/CollisionShape3D.disabled = true
	
	_hurtbox_3d.took_hit.connect(func _on_hurt_box_took_hit(_hit_box: Hitbox3D) -> void:
		# If the hitbox is the player's, damage is immediately applied. Otherwise the damage is calculated further down.
		health -= _hit_box.damage if _hit_box.get_owner() is PlayerFPSController else 0
		if _hit_box.get_owner() is PlayerFPSController:
			cruelty += 1
		$Damage.play()
		#print(_hit_box.damage_source)
		debug_label.text = str(health)
		if _hit_box.get_parent() is Trap3D or _hit_box.get_owner() is Trap3D:
			var trap = _hit_box.get_parent()
			if trap.instant_death == true:
				health -= _hit_box.damage
				return
			cruelty += trap.cruelty_rating
			var trap_index = interacted_with_trap.find(trap.trap_name)
			var trap_dictionary = interacted_with_trap[trap_index]
			var trap_interact_threshold := randi_range(3, 6)
			print("trap_interact_threshold is " + str(trap_interact_threshold))
			if trap_dictionary["times_interacted_with"] > trap_interact_threshold:
				return
			elif evasion_chance < trap.tamper_chance or trap_dictionary["times_interacted_with"] < trap_interact_threshold:
				health -= _hit_box.damage
				print("enemy should take damage")
				print(_hit_box.damage)
		#elif _hit_box.get_owner() is PlayerFPSController:
			#health -= _hit_box.damage
			#print("damaged by player")
			#print("player damage is " + str(_hit_box.damage))
		)
	
	$VisionTimer.timeout.connect(_on_vision_timer_timeout)
	_roaming_ray_cast.add_exception($VisionArea)
	
	# If the burglar spots the player while the awareness timer is running, the timer is stopped
	if $AwarenessTimer.time_left > 0 and player_spotted == true:
		print("awareness timer stopped")
		$AwarenessTimer.stop()
	

func _physics_process(delta: float) -> void:
	print("current_entryway is " + str(current_entryway))
	print("current_entryway_just_updated is " + str(current_entryway_just_updated))
	print("velocity.length_squared is " + str(velocity.length_squared()))
	#print("footstep_area_occupied is " + str(footstep_area_occupied))
	#var destination = _navigation_agent_3d.get_next_path_position()
	#var local_destination = destination - global_position
	#var path_direction = local_destination.normalized()
	#
	#if _navigation_agent_3d.is_navigation_finished():
		#return
	#
	##look_at(destination)
	## Look at smooth code I ripped off google
	#var target_transform = transform.looking_at(destination)
	#var current_quat = Quaternion(transform.basis)
	#var target_quat = Quaternion(target_transform.basis)
	#var blended_quat = current_quat.slerp(target_quat, 0.1)
	#transform.basis = Basis(blended_quat)
	##
	#
	#velocity = path_direction * walk_speed
	#move_and_slide()
	
	#print(vision_target)
	#print($AwarenessTimer.time_left)
	#print(vision_target_just_turned_player)
	#print("current lure is " + str(lure))
	#print("current state is " + str(current_state))
	#print("time left on lure cooldown is " + str(_lure_interaction_cooldown.time_left))
	print(str(self) + "'s current_state is " + str(current_state))
	#print(last_state)
	#print($AwarenessTimer.time_left)
	#print(walk_speed)
	#print("current_state is " + str(current_state))
	# Used to determine if burglar will take damage from a trap
	
	# Application of gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = maxf(velocity.y, -max_fall_speed)
	
	evasion_chance = randi_range(1, 100)
	
	# Handles player detection
	var vision_collider = $VisionRayCast.get_collider()
	if vision_collider == player:
		player_spotted = true
	else:
		player_spotted = false
	
	# Walk noises
	if velocity.length() > 2.2 or current_state in movement_states_array:
		moving = true
		#$BurglarSkinV2/AnimationPlayer.play("run")
	else:
		moving = false
		#$BurglarSkinV2/AnimationPlayer.play("idle")
	
	
	# Updates the nearest exit point for the burglar
	nearest_poxit = find_closest_node_to_point(Blackboard.point_of_entries, self.global_position)
	#point_of_exit = nearest_poxit
	# Updates the closest entrypoint relative to the player, regardless of the burglar's state. 
	#That is why it was moved outside of the statemachine.
	var nearest_entry_relative_to_player = find_closest_node_to_point(Blackboard.point_of_entries, player.global_position)
	var nearest_entry_relative_to_burglar = find_closest_node_to_point(Blackboard.point_of_entries, self.global_position)
	
	if vision_target_just_turned_entry:
		look_at(player.global_position)
		rotation.x = 0
		rotation.z = 0
	
	
	#print(Blackboard.point_of_entries)
	#print("burglar near relative entry is " + str(near_relative_entry))
	#print(global_position.distance_squared_to(nearest_entry_relative_to_player.global_position))
	#print(vision_target)
	
	# Determines if burglar is close to the nearest entry relative to the player
	if global_position.distance_squared_to(nearest_entry_relative_to_player.global_position) <= 1.00 and %RoamingRayCast.get_collider() is Interactable3D:
		near_relative_entry = true
	else:
		near_relative_entry = false
	
	match current_state:
		State.ROAMING:
			look_at(Blackboard.house_origin)
			rotation.x = 0
			rotation.z = 0
			if _roaming_ray_cast.is_colliding():
				var colliding_object = _roaming_ray_cast.get_collider()
				if colliding_object is PlayerFPSController:
					player = colliding_object
				elif colliding_object in Blackboard.point_of_entries:
					point_of_entry = colliding_object
					burglar_path_stop.emit()
					if colliding_object is Window3D:
						stored_y_position = global_position.y
					get_tree().create_timer(0.5).timeout.connect(
						set_current_state.bind(State.MOVING_TO_POE)
					)
		State.MOVING_TO_POE:
			look_at(point_of_entry.global_position, Vector3.UP)
			rotation.x = 0.0
			rotation.z = 0.0
			if point_of_entry != null:
				if point_of_entry is Window3D:
					#print("Window")
					global_position.y = stored_y_position
				var direction := global_position.direction_to(point_of_entry.global_position) 
				var desired_velocity := direction * walk_speed
				var velocity_distance := velocity.distance_to(desired_velocity)
				
				_navigation_agent_3d.set_target_position(point_of_entry.global_position)
				var destination = _navigation_agent_3d.get_next_path_position()
				var local_destination = destination - global_position
				var path_direction = local_destination.normalized()
				global_position.y = stored_y_position
				
				velocity = velocity.move_toward(
					desired_velocity,
					velocity_distance * walk_acceleration_factor * delta
				)
				var distance_between_self_and_poe = global_position.distance_to(point_of_entry.global_position)
				if not _navigation_agent_3d.is_navigation_finished() and distance_between_self_and_poe > 3.0:
					velocity = path_direction * walk_speed
					move_and_slide()
				elif not _navigation_agent_3d.is_navigation_finished() and distance_between_self_and_poe < 3.0:
					velocity = velocity.move_toward(Vector3.ZERO, walk_acceleration_factor * delta)
					move_and_slide()
				else: 
					velocity = velocity.move_toward(
					desired_velocity,
					velocity_distance * walk_acceleration_factor * delta)
					move_and_slide()
				
				
				#var distance_between_self_and_poe = global_position.distance_to(point_of_entry.global_position)
				if distance_between_self_and_poe < 1.5 or current_entryway != null:
					print(str(self) + " should switch to entering state")
					get_tree().create_timer(0.5).timeout.connect(
						set_current_state.bind(State.ENTERING)
					)
		State.ENTERING:
			if player_spotted == true:
				#look_at(player.global_position, Vector3.UP)
				rotation.x = 0.0
				rotation.z = 0.0
			else:
				pass
		State.LOOTING:
			if footstep_area_occupied and player.player_in_loud_motion == true:
				print("should detect player")
				player_spotted = true
			
			if _roaming_ray_cast.is_colliding():
				if _roaming_ray_cast.get_collider() is Door3D:
					var door = _roaming_ray_cast.get_collider()
					look_at(door.global_position, Vector3.UP)
					rotation.x = 0
					rotation.z = 0
					if global_position.distance_to(door.global_position) < 1.5:
						global_position.y = stored_y_position
						var direction := global_position.direction_to(door.global_position) 
						var desired_velocity := direction * walk_speed
						var velocity_distance := velocity.distance_to(desired_velocity)
						velocity = velocity.move_toward(
							desired_velocity,
							velocity_distance * walk_acceleration_factor * delta
						)
						
						move_and_slide()
			
			
			_hurtbox_3d.took_hit.connect(func(_hit_box: Hitbox3D) -> void:
				# If player punches the burglar while hidden, the burglar is stunned
				if _hit_box.damage_source == 1 and player_spotted == false and current_state == 3:
					set_current_state(State.STUNNED_BY_PLAYER)
					last_state = 7
				elif _hit_box.get_parent() is Trap3D and current_state == 3:
					last_state = 3
					set_current_state(State.STUNNED_BY_TRAP)
			)
			filtered_loot_objects = filtered_loot_objects.filter(func(loot_object: LootObject):
				return loot_object.is_looted == false
				)
			nearest_loot_object = find_closest_node_to_point(filtered_loot_objects, self.global_position)
			if nearest_loot_object:
				# Door realignment logic. If the burglar has recently updated their entryway and that entryway is not null, 
				# they will path towards that entryway. Otherwise, they will path towards the nearest loot object as normal. 
				# This is to prevent the burglar from getting stuck on corners while trying to exit through a door.
				if current_entryway_just_updated == true and current_entryway != null:
					entryway_reference = current_entryway
					_navigation_agent_3d.set_target_position(entryway_reference.global_position)
				else:
					_navigation_agent_3d.set_target_position(nearest_loot_object.global_position)
				var destination = _navigation_agent_3d.get_next_path_position()
				var local_destination = destination - global_position
				var path_direction = local_destination.normalized()
				# Look Logic
				var target_transform: Transform3D = global_transform.looking_at(destination, Vector3.UP)
				var target_quat = target_transform.basis.get_rotation_quaternion()
				var current_quat = global_transform.basis.get_rotation_quaternion()
				
				var direction := global_position.direction_to(nearest_loot_object.global_position)
				var desired_velocity := direction * walk_speed
				desired_velocity += calculate_avoidance_force() * delta
				var velocity_distance := velocity.distance_to(desired_velocity)
				global_position.y = stored_y_position
				if not _navigation_agent_3d.is_navigation_finished():
					velocity = path_direction * walk_speed
					move_and_slide()
				else:
					velocity = velocity.move_toward(Vector3.ZERO, velocity_distance * walk_acceleration_factor * delta)
					look_at(nearest_loot_object.global_position, Vector3.UP)
					rotation.x = 0
					rotation.z = 0
				
				looting_timer_node.wait_time = nearest_loot_object.looting_duration
				
				# If the burglar is inside the range of the loot object, this should occur
				if is_looting == true and nearest_loot_object.is_looted == false and nearest_loot_object != null:
					# Local variable created in preparation for the "nearest loot object"'s deletion from the filtered array
					var looted_object = nearest_loot_object
					_animation_player.play("looting")
					
					looting_timer_node.wait_time = looted_object.looting_duration
					looting_timer_node.timeout.connect(func() -> void:
						_animation_player.play("RESET")
						is_looting = false
						looted_object.is_looted = true
						looted_object.hide()
						has_loot = true
						)
					## Burglar comes to a stop
					#velocity = velocity.move_toward(Vector3.ZERO, velocity_distance * walk_acceleration_factor * delta)
				#else:
					#velocity = velocity.move_toward(
						#desired_velocity,
						#velocity_distance * walk_acceleration_factor * delta
					#)
				
				if player_spotted == false:
					if velocity.length_squared() == 0.00 and current_entryway != null and current_entryway_just_updated == true and current_entryway is Door3D:
						var entryway_look_reference = current_entryway
						look_at(entryway_look_reference.global_position, Vector3.UP)
						#var look_target = global_position + velocity
						#look_at(look_target, Vector3.UP)
						#look_at(destination, Vector3.UP)
					else:
						# Look Logic Continued
						var next_quat: Quaternion = current_quat.slerp(target_quat, look_rotation_speed * delta)
						global_transform.basis = Basis(next_quat)
					#rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), delta * look_rotation_speed)
					#rotation.y = rotate_toward(rotation.y, atan2(velocity.x,velocity.z), delta * look_rotation_speed)
					
				else:
					look_at(player.global_position, Vector3.UP)
				rotation.x = 0
				rotation.z = 0
				
				move_and_slide()
				
				# Assigns the point of exit for the burglar. 80/20 chance of the burglar leaving
				# where they came, or picking the closest door/window.
				if chance <= 80:
					point_of_exit = point_of_entry
				else:
					point_of_exit = nearest_poxit
				#point_of_exit = nearest_poxit
			
			# Conditions for the transition to exiting state
			if filtered_loot_objects.is_empty() and current_state != 15: 
				get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.MOVING_TO_POXIT))
			
			if player_spotted == true:
				get_tree().create_timer(0.25).timeout.connect(set_current_state.bind(State.COMBAT))
			
			# Lure transition
			if being_lured == true:
				get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.MOVING_TO_LURE))
			
		State.MOVING_TO_POXIT:
				print("moving to poxit")
				print("point of exit is " + str(point_of_exit))
				#var direction := global_position.direction_to(point_of_exit.global_position) 
				#var desired_velocity := direction * walk_speed
				#var velocity_distance := velocity.distance_to(desired_velocity)
				#velocity = velocity.move_toward(
					#desired_velocity,
					#velocity_distance * walk_acceleration_factor * delta
				#)
				var direction := global_position.direction_to(point_of_exit.global_position) 
				var desired_velocity := direction * walk_speed
				var velocity_distance := velocity.distance_to(desired_velocity)
				
				_navigation_agent_3d.set_target_position(point_of_exit.global_position)
				var destination = _navigation_agent_3d.get_next_path_position()
				var local_destination = destination - global_position
				var path_direction = local_destination.normalized()
				global_position.y = stored_y_position
				if not _navigation_agent_3d.is_navigation_finished():
					velocity = path_direction * walk_speed
					move_and_slide()
				else: 
					velocity = velocity.move_toward(
					desired_velocity,
					velocity_distance * walk_acceleration_factor * delta)
					move_and_slide()
				var distance_between_self_and_poxit = global_position.distance_to(point_of_exit.global_position)
				print("distance between self and exit is " + str(distance_between_self_and_poxit))
				
				#velocity = path_direction * walk_speed
				#move_and_slide()
				global_position.y = stored_y_position
				#look_at(point_of_exit.global_position)
				# Look Logic
				var target_transform: Transform3D = global_transform.looking_at(destination, Vector3.UP)
				var target_quat = target_transform.basis.get_rotation_quaternion()
				var current_quat = global_transform.basis.get_rotation_quaternion()
				
				var look_vector = point_of_exit.global_position - global_position
				var look_angle = atan2(look_vector.x, look_vector.z)
				if distance_between_self_and_poxit > 3.0:
					#rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), delta * look_rotation_speed)
					# Look Logic Continued
					var next_quat: Quaternion = current_quat.slerp(target_quat, look_rotation_speed * delta)
					global_transform.basis = Basis(next_quat) 
				else:
					#rotation.y = rotate_toward(rotation.y, look_angle, delta * look_rotation_speed)
					look_at(point_of_exit.global_position, Vector3.UP)
				rotation.x = 0
				rotation.z = 0
				
				if distance_between_self_and_poxit < 1.8:
					print("burglar exiting")
					last_state = 4
					get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.EXITING))

		State.EXTRACTION:
				var nearest_extraction_point = find_closest_node_to_point(Blackboard.extraction_points, self.global_position)
				var direction := global_position.direction_to(nearest_extraction_point.global_position) 
				var desired_velocity := direction * walk_speed
				var velocity_distance := velocity.distance_to(desired_velocity)
				if global_position.distance_to(nearest_extraction_point.global_position) >= 2.0:
					global_position.y = stored_y_position
					look_at(nearest_extraction_point.global_position)
					velocity = velocity.move_toward(
						desired_velocity,
						velocity_distance * run_acceleration_factor * delta
					)
					move_and_slide()
				elif global_position.distance_to(nearest_extraction_point.global_position) <= 1.0:
					global_position.y = stored_y_position
					velocity = velocity.move_toward(Vector3.ZERO, walk_acceleration_factor * delta)
					move_and_slide()
		State.COMBAT:
			print($AwarenessTimer.time_left)
			var _on_opposing_spaces = (player.is_inside_home == true and is_inside_home == false) or (player.is_inside_home == false and is_inside_home == true)
			var needs_to_exit = player.is_inside_home == false and is_inside_home == true
			var needs_to_enter = player.is_inside_home == true and is_inside_home == false
			#if _on_opposing_spaces and $AwarenessTimer.time_left < 9.0 and door_interaction_cooldown_timer.is_stopped() and global_position.distance_to(player.global_position) > 25.0:
				#set_current_state(State.REROAMING)
			if needs_to_exit and $AwarenessTimer.time_left < 9.0 and door_interaction_cooldown_timer.is_stopped() and global_position.distance_to(player.global_position) > 25.0:
				set_current_state(State.REROAMING)
			if needs_to_enter and $AwarenessTimer.time_left < 9.0 and door_interaction_cooldown_timer.is_stopped():
				set_current_state(State.REROAMING)
			_hurtbox_3d.took_hit.connect(func(_hit_box: Hitbox3D) -> void:
				if _hit_box.get_parent() is Trap3D:
					print("trap chance to stun is " + str(chance_to_stun))
				if _hit_box.get_parent() is Trap3D: 
					var trap = _hit_box.get_parent()
					if trap.instant_death == true or current_state == 7 and chance_to_stun < 0.5:
						last_state = 7
						set_current_state(State.STUNNED_BY_TRAP)
				)
			
			if $VisionTargetChangeTimer.is_stopped():
				if player_spotted == true:
					vision_target = player
				#if vision_target_just_turned_entry:
					#vision_target = player
					#return
				#if player_spotted == false and $AwarenessTimer.time_left < 8.0:
					#vision_target = nearest_entry_relative_to_player
				
			
			var direction := global_position.direction_to(player.global_position) 
			var desired_velocity := direction * walk_speed
			var velocity_distance := velocity.distance_to(desired_velocity)
			
			_navigation_agent_3d.set_target_position(player.global_position if player_spotted == true else player_out_of_sight_pos)
			var destination = _navigation_agent_3d.get_next_path_position()
			var local_destination = destination - global_position
			var path_direction = local_destination.normalized()
			
			#global_position.y = stored_y_position
			if _grounding_ray_cast.is_colliding():
				var y_pos = _grounding_ray_cast.get_collision_point()
				global_position.y = y_pos.y
			look_at(vision_target.global_position)
			rotation.x = 0
			rotation.z = 0
			
			if global_position.distance_squared_to(player.global_position) <= 15.0 or _navigation_agent_3d.is_target_reached() or current_entryway_just_updated == true:
				print("steering")
				_navigation_agent_3d.set_target_position(self.global_position)
				velocity = velocity.move_toward(
				desired_velocity,
				velocity_distance * walk_acceleration_factor * delta)
				move_and_slide()
			else:
				print("taking path")
				_navigation_agent_3d.set_target_position(player.global_position if player_spotted == true else player_out_of_sight_pos)
				velocity = path_direction * walk_speed
				move_and_slide()
			
			
			
			if not _navigation_agent_3d.is_navigation_finished():
				velocity = path_direction * walk_speed
				move_and_slide()
			else: 
				velocity = velocity.move_toward(
				desired_velocity,
				velocity_distance * walk_acceleration_factor * delta)
				move_and_slide()
			
			
			
			
			
			
			
			## Closing the distance between self and player
			#if weapon_type is MeleeWeapon:
				#global_position.y = stored_y_position
				#look_at(vision_target.global_position)
				#rotation.x = 0
				#rotation.z = 0
				#var direction := global_position.direction_to(vision_target.global_position) 
				#var desired_velocity := direction * (walk_speed * 1.75)
				#var velocity_distance := velocity.distance_to(desired_velocity)
				#velocity = velocity.move_toward(
					#desired_velocity,
					#velocity_distance * run_acceleration_factor * delta
				#)
				#move_and_slide()
			#elif weapon_type is Firearm:
				#global_position.y = stored_y_position
				#look_at(player.global_position)
				#rotation.x = 0
				#rotation.z = 0
				#velocity = velocity.move_toward(Vector3.ZERO, run_acceleration_factor * delta)
				#
			if global_position.distance_squared_to(player.global_position) <= 1.5 and weapon_type is MeleeWeapon:
				set_current_state(State.STRIKE_DELAY)
			elif weapon_type is Firearm and player_spotted == true and player_spotted_just_true == false and $ShootCooldown.time_left == 0:
				set_current_state(State.SHOOT)
			
			$AwarenessTimer.timeout.connect(func() -> void:
				var forbidden_states = [4,5,6]
				if is_inside_home == true:
					print("lost sight of player or lost interest, returning to looting state")
					set_current_state(State.LOOTING)
				else:
					print("out of home, returning to inside of home")
					set_current_state(State.REROAMING)
				)
			
			# Allows burglar to exit window in the midst of combat, most probably while chasing the player
			if _roaming_ray_cast.get_collider() is Window3D:
				var window = _roaming_ray_cast.get_collider()
				var distance_between_self_and_window = global_position.distance_to(window.global_position)
				print(distance_between_self_and_window)
				if distance_between_self_and_window < 1.8:
					# The area the burglar is standing on determines whether it's entering or exiting
					if window.currently_occupied_area == "$ExitingArea":
						print("should begin exiting state")
						last_state = 7
						get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.EXITING))
					elif window.currently_occupied_area == "$EnteringArea":
						print("should begin entering state")
						last_state = 7
						get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.ENTERING))
			
		State.SHOOT:
			global_position.y = stored_y_position
			look_at(player.global_position)
			rotation.x = 0
			rotation.z = 0
		State.STRIKE:
			look_at(player.global_position)
			rotation.x = 0
			rotation.z = 0
		State.REROAMING:
			var target_destination = nearest_poxit._reroaming_target
			global_position.y = stored_y_position
			var direction := global_position.direction_to(target_destination.global_position)
			var desired_velocity := direction * walk_speed
			var velocity_distance := velocity.distance_to(desired_velocity)
			
			_navigation_agent_3d.set_target_position(nearest_poxit.global_position)
			var destination = _navigation_agent_3d.get_next_path_position()
			var local_destination = destination - global_position
			var path_direction = local_destination.normalized()
			if not _navigation_agent_3d.is_navigation_finished():
				velocity = path_direction * walk_speed
				move_and_slide()
			else: 
				velocity = velocity.move_toward(
				desired_velocity,
				velocity_distance * walk_acceleration_factor * delta)
				move_and_slide()
			
			#var look_vector = nearest_poxit.global_position - global_position
			#var look_angle = atan2(look_vector.x, look_vector.z)
			
			# Look Logic
			var target_transform: Transform3D = global_transform.looking_at(destination, Vector3.UP)
			var target_quat = target_transform.basis.get_rotation_quaternion()
			var current_quat = global_transform.basis.get_rotation_quaternion()
			
			var distance_between_self_and_poe = global_position.distance_to(nearest_poxit.global_position)
			
			if distance_between_self_and_poe > 3.0 or temp_entryway == null:
				# Look Logic Continued
				var next_quat: Quaternion = current_quat.slerp(target_quat, look_rotation_speed * delta)
				global_transform.basis = Basis(next_quat)
				#rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), delta * look_rotation_speed) 
			else:
				look_at(nearest_poxit.global_position)
			rotation.x = 0
			rotation.z = 0
			
			if distance_between_self_and_poe < 1.8 and current_entryway != null:
				get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.ENTERING if is_inside_home == false else State.EXITING))
		State.MOVING_TO_LURE:
			print("lure_delta_timer is " + str(lure_delta_timer))
			var stuck = velocity.length_squared() > 0.1 and velocity.length_squared() < 0.2
			if stuck and lure_delta_timer <= 2.5:
				lure_delta_timer += delta
			
			
			
			_hurtbox_3d.took_hit.connect(func(_hit_box: Hitbox3D) -> void:
				# If player punches the burglar while hidden, the burglar is stunned
				if _hit_box.damage_source == 1 and player_spotted == false and current_state == 14:
					set_current_state(State.STUNNED_BY_PLAYER)
				elif _hit_box.get_parent() is Trap3D and current_state == 14:
					last_state = 14
					set_current_state(State.STUNNED_BY_TRAP)
			)
			
			if _roaming_ray_cast.is_colliding():
				if _roaming_ray_cast.get_collider() is Door3D:
					var door = _roaming_ray_cast.get_collider()
					look_at(door.global_position, Vector3.UP)
					rotation.x = 0
					rotation.z = 0
					if global_position.distance_to(door.global_position) < 1.5:
						global_position.y = stored_y_position
						var direction := global_position.direction_to(door.global_position) 
						var desired_velocity := direction * walk_speed
						var velocity_distance := velocity.distance_to(desired_velocity)
						velocity = velocity.move_toward(
							desired_velocity,
							velocity_distance * walk_acceleration_factor * delta
						)
						
						move_and_slide()
			
			#print(lure_delta_timer)
			if lure != null:
				_navigation_agent_3d.set_target_position(lure.global_position)
				var destination = _navigation_agent_3d.get_next_path_position()
				var local_destination = destination - global_position
				var path_direction = local_destination.normalized()
				# Look Logic
				var target_transform: Transform3D = global_transform.looking_at(destination, Vector3.UP)
				var target_quat = target_transform.basis.get_rotation_quaternion()
				var current_quat = global_transform.basis.get_rotation_quaternion()
				
				var direction := global_position.direction_to(lure.global_position)
				var desired_velocity := direction * walk_speed
				desired_velocity += calculate_avoidance_force() * delta
				var velocity_distance := velocity.distance_to(desired_velocity)
				global_position.y = stored_y_position
				if not _navigation_agent_3d.is_navigation_finished():
					velocity = path_direction * walk_speed
					move_and_slide()
				else:
					velocity = velocity.move_toward(Vector3.ZERO, velocity_distance * walk_acceleration_factor * delta)
					look_at(lure.global_position, Vector3.UP)
					rotation.x = 0
					rotation.z = 0
				#var nearest_entry_relative_to_lure = find_closest_node_to_point(Blackboard.point_of_entries, lure.global_position)
				#if not $VisionArea.overlaps_area(lure):
					#vision_target = nearest_entry_relative_to_lure
				#vision_target = lure
				#look_at(vision_target.global_position)
				if player_spotted == false:
					if velocity.length_squared() > 0.01:
							# Look Logic Continued
							var next_quat: Quaternion = current_quat.slerp(target_quat, look_rotation_speed * delta)
							global_transform.basis = Basis(next_quat)
				else:
					look_at(player.global_position, Vector3.UP)
					get_tree().create_timer(0.25).timeout.connect(set_current_state.bind(State.COMBAT))
					lure = null
				rotation.x = 0
				rotation.z = 0
			if lure != null:
				var distance_between_self_and_lure = global_position.distance_to(lure.global_position)
				if distance_between_self_and_lure < 1.5:
					being_lured = false
					get_tree().create_timer(5.0).timeout.connect(func() -> void:
						#lure = null
						if is_inside_home == true:
							print("finished being lured, returning to looting")
							set_current_state(State.LOOTING)
						else:
							print("out of home because was lured, returning to inside of home")
							set_current_state(State.REROAMING)
					)
		State.WINDOW_WAIT:
			if current_entryway is Window3D:
				var window = current_entryway
				if not window.priority_list.is_empty():
					prioritized_burglar = window.priority_list[0]
			if prioritized_burglar == self:
				get_tree().create_timer(0.5).timeout.connect(set_current_state.bind(State.ENTERING))

func _on_vision_timer_timeout():
	#print("timer working") 
	var overlaps = $VisionArea.get_overlapping_bodies()
	#print(overlaps)
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap == player:
				var player_position = player.global_position
				$VisionRayCast.look_at(player_position, Vector3.UP)
				$VisionRayCast.force_raycast_update()
				
				if $VisionRayCast.is_colliding():
					var collider = $VisionRayCast.get_collider()
					
					if collider == player:
						pass



func find_closest_node_to_point(array, point):
	var closest_node = null
	var closest_node_distance = 0.0
	for i in array:
		var current_node_distance = point.distance_to(i.global_position)
		if closest_node == null or current_node_distance < closest_node_distance:
			closest_node = i
			closest_node_distance = current_node_distance
	return closest_node
