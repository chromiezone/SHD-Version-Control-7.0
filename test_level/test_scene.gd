extends Node3D


@export var enemy_spawn_time := 0.0
@onready var _path_follow_3d: PathFollow3D = $Spawner/Path3D/PathFollow3D
@onready var _indoor_area: Area3D = $IndoorArea


enum Stage {
	SETUP,
	DEFENSE,
	CLEANUP,
	INTERMISSION,
}

@export var setup_time: float = 15.0
@export var cleanup_time: float = 60.0

var burglar_count : int = 0
var burglars_have_begun : bool = false
var power_on := true

# Scoring
var cruelty_score : int = 100
var safety_inspection_score : int = 100
var health_score : int = 100 
var overall_score : float = 0.0

func calculate_score() -> float:
	var cruelty_factor = 0.50
	var safety_factor = 0.30
	var health_factor = 0.20
	
	var weighted_cruelty = cruelty_score * cruelty_factor
	var weighted_safety = safety_inspection_score * safety_factor
	var weighted_health = health_score * health_factor
	
	var score = weighted_cruelty + weighted_safety + weighted_health
	return score

var current_stage : Stage = Stage.SETUP:
	set = set_current_stage

func set_current_stage(new_stage: Stage) -> void:
	current_stage = new_stage
	match current_stage:
		Stage.SETUP:
			$Terminal.can_interact = true
			get_tree().create_timer(setup_time).timeout.connect(
				set_current_stage.bind(Stage.DEFENSE)
			)
		Stage.DEFENSE:
			$Terminal.is_active = false
			$Terminal.can_interact = false
			#night_time_configuration()
			var burglar := preload("res://enemies/burglar.tscn").instantiate()
			burglar.position.y = -0.175
			await get_tree().create_timer(enemy_spawn_time).timeout
			_path_follow_3d.add_child(burglar)
			burglars_have_begun = true
			burglar_count += 1
			burglar.connect("enemy_died", func() -> void:
				burglar_count -= 1
				print("burglar cruelty is " + str(burglar.cruelty))
				cruelty_score -= burglar.cruelty
				)
			_path_follow_3d.progress = possible_spawns.pick_random()
			burglar.connect("burglar_path_stop", func() -> void:
				move_speed = 0.0
				)
			$ExtractionZone/ExtractionArea.body_entered.connect(func(body: Node3D) -> void:
				if body is Enemy3D and body.has_loot == true:
					print("Game over via burglar exiting with loot")
				) 
		Stage.CLEANUP:
			get_tree().create_timer(cleanup_time).timeout.connect(
				set_current_stage.bind(Stage.INTERMISSION)
			)
		Stage.INTERMISSION:
			for child in $PointOfEntries.get_children():
				if child is Door3D:
					var door = child
					if door.broken == true:
						safety_inspection_score -= 1
			
			safety_inspection_score = safety_inspection_score - (Globals.trap_count * 5)
			health_score = health_score - ($Player.health_score * 10)
			#overall_score = (safety_inspection_score + 4) * (health_score + 5) * (cruelty_score + 5) - 100
			overall_score = calculate_score()
			print("cruelty score is " + str(cruelty_score))
			print("safety inspection score is  " + str(safety_inspection_score))
			print("health score is " + str(health_score))
			print("overall score is " + str(overall_score))

var possible_spawns := [140.0] #[0.86, 25.0, 55.0, 80.0, 110, 140, 160, 188]
var current_path_progress : float
var move_speed := 1.0

func day_time_configuration() -> void:
	$DirectionalLight3D.show()
	$WorldEnvironment.environment.background_mode = 2
	$WorldEnvironment.environment.fog_enabled = false
	$WorldEnvironment.environment.sky = Sky.new()
	$WorldEnvironment.environment.sky.sky_material = preload("res://test_level/test_scene_sky.tres")

func night_time_configuration() -> void:
	$DirectionalLight3D.hide()
	$WorldEnvironment.environment.background_mode = 1
	$WorldEnvironment.environment.background_color = Color(0, 0, 0, 255)
	$WorldEnvironment.environment.fog_enabled = true

func _ready() -> void:
	#power_on = false
	day_time_configuration()
	#night_time_configuration()
	
	Globals.main_level = self
	set_current_stage(Stage.SETUP)
	
	
	_indoor_area.body_entered.connect(func(body: Node3D) -> void:
		#print(body)
		if body is Enemy3D:
			print("enemy entered home")
			body.is_inside_home = true
		)
	_indoor_area.body_exited.connect(func(body: Node3D) -> void:
		#print("body is " + str(body))
		if body is Enemy3D:
			print("enemy exited home")
			body.is_inside_home = false
		)
	
	_indoor_area.body_entered.connect(func(body: Node3D) -> void:
		#print(body)
		if body is PlayerFPSController:
			print("player entered home")
			body.is_inside_home = true
		)
	_indoor_area.body_exited.connect(func(body: Node3D) -> void:
		#print("body is " + str(body))
		if body is PlayerFPSController:
			print("player exited home")
			body.is_inside_home = false
		)
	#var burglar := preload("res://enemies/burglar.tscn").instantiate()
	#burglar.position.y = -0.175
	#await get_tree().create_timer(enemy_spawn_time).timeout
	#_path_follow_3d.add_child(burglar)
	#_path_follow_3d.progress = possible_spawns.pick_random()
	#burglar.connect("burglar_path_stop", func() -> void:
		#move_speed = 0.0
		#)
	#
	#$ExtractionZone/ExtractionArea.body_entered.connect(func(body: Node3D) -> void:
		#if body is Enemy3D and body.has_loot == true:
			#print("Game over via burglar exiting with loot")
		# )
	
	

func _physics_process(delta: float) -> void:
	#print("trap count is " + str(Globals.trap_count))
	#print("current stage is " + str(current_stage))
	Globals.main_level = self
	# Gives the Burglar the location of the house's origin
	Burglar.Blackboard.house_origin = $TestHouse/HouseOrigin.global_position
	# Gives the Burglar POEs
	Burglar.Blackboard.point_of_entries = $PointOfEntries.get_children()
	# Gives the Burglar Loot objects
	Burglar.Blackboard.loot_objects = $LootObjects.get_children()
	# Gives the Burglar extraction points
	Burglar.Blackboard.extraction_points = $ExtractionZone/ExtractionPoints.get_children()
	
	match current_stage:
		Stage.DEFENSE:
			if burglars_have_begun == true and burglar_count == 0:
				set_current_stage(Stage.CLEANUP)
	
	
	
	
	_path_follow_3d.progress += move_speed * delta

func _process(_delta: float) -> void:
	# Allows for access to the BuyMenu via the terminal
	$CanvasLayer/BuyMenu.is_active = $Terminal.is_active
	$CanvasLayer/BuyMenu.terminal = $Terminal
	# Updates player's money in the player UI
	$CanvasLayer/PlayerUI.money_label.text = "$" + str(Globals.player_money)
	# Gives reference to the player to the Buy Menu.
	$CanvasLayer/BuyMenu.player = $Player
	
	# Sets up power switch
	power_on = $PowerSwitch.power_on
