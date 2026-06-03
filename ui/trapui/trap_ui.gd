class_name TrapUI extends Control

var is_active := false: set = set_is_active
@onready var h_box_container: HBoxContainer = $ScrollContainer/HBoxContainer
var current_trap : PackedScene = null


var player : PlayerFPSController = null

func set_is_active(new_value: bool) -> void:
	is_active = new_value
	visible = is_active
	FixedTrapVisual.Blackboard.trap_menu_open = is_active
	
	

func _ready() -> void:
	player = Globals.player
	set_is_active(is_active)
	
	
	
	#create_new_trap_button()
	
	$ScrollContainer/HBoxContainer/DoorBombE.pressed.connect(func() -> void:
		player.selected_fixed_trap = "DoorBombE"
		is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	$ScrollContainer/HBoxContainer/DoorTorchM.pressed.connect(func() -> void:
		player.selected_fixed_trap = "DoorTorchM"
		is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	$ScrollContainer/HBoxContainer/Nailboard.pressed.connect(func() -> void:
		var nailboard_visual = preload("res://traps/visuals/NailboardVisual.tscn").instantiate()
		var nailboard = preload("res://traps/Nailboard.tscn")
		nailboard_visual.position = player._trap_visual_position.position
		nailboard_visual.rotation.y = - PI / 2.0
		player._trap_visual_position.add_child(nailboard_visual)
		player._trap_visual_position.move_child(nailboard_visual, 0)
		current_trap = nailboard
		is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	$ScrollContainer/HBoxContainer/BearTrap.pressed.connect(func() -> void:
		var beartrap_visual = preload("res://traps/visuals/BearTrapVisual.tscn").instantiate()
		var beartrap = preload("res://traps/BearTrap.tscn")
		beartrap_visual.position = player._trap_visual_position.position
		player._trap_visual_position.add_child(beartrap_visual)
		player._trap_visual_position.move_child(beartrap_visual, 0)
		current_trap = beartrap
		is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	$ScrollContainer/HBoxContainer/GlueTrap.pressed.connect(func() -> void:
		var gluetrap_visual = preload("res://traps/visuals/GlueTrapVisual.tscn").instantiate()
		var gluetrap = preload("res://traps/GlueTrap.tscn")
		gluetrap_visual.position = player._trap_visual_position.position
		gluetrap_visual.position.z = -1.0
		player._trap_visual_position.add_child(gluetrap_visual)
		player._trap_visual_position.move_child(gluetrap_visual, 0)
		current_trap = gluetrap
		is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	$ScrollContainer/HBoxContainer/SpeakerLure.pressed.connect(func() -> void:
		var speakerlure_visual = preload("res://traps/visuals/SpeakerLureVisual.tscn").instantiate()
		var speakerlure = preload("res://traps/SpeakerLure.tscn")
		speakerlure_visual.position = player._trap_visual_position.position
		speakerlure_visual.position.z = -1.0
		player._trap_visual_position.add_child(speakerlure_visual)
		player._trap_visual_position.move_child(speakerlure_visual, 0)
		current_trap = speakerlure
		is_active = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)

func create_new_trap_button() -> void:
	var button := Button.new()
	h_box_container.add_child(button)
	button.text = "Board w/ Nails"
	


func _unhandled_input(event: InputEvent) -> void:
	var is_tab_pressed := event.is_action_pressed("trap_menu")
	
	if is_tab_pressed and is_active == false and Globals.main_level.current_stage == 0 :
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif is_tab_pressed and is_active == true:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if is_tab_pressed and Globals.main_level.current_stage == 0:
		set_is_active(not is_active)
	elif Globals.main_level.current_stage > 0:
		set_is_active(false)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
	var trap_to_be_copied = player._trap_visual_position.get_child(0)
	var is_f_pressed := event.is_action_pressed("confirm")
	var trap : Trap3D = null
	if is_f_pressed and current_trap != null and trap_to_be_copied is Area3D and trap_to_be_copied.meets_prerequisites == true:
		match trap_to_be_copied.trap_name:
			"Nailboard":
				trap = preload("res://traps/Nailboard.tscn").instantiate()
			"BearTrap":
				trap = preload("res://traps/BearTrap.tscn").instantiate()
			"GlueTrap":
				trap = preload("res://traps/GlueTrap.tscn").instantiate()
			"SpeakerLure":
				trap = preload("res://traps/SpeakerLure.tscn").instantiate()
		if Globals.player.inventory.has(trap.trap_name):
			Globals.player.inventory[trap.trap_name] -= 1
		get_tree().get_root().add_child(trap)
		trap.global_position = trap_to_be_copied.global_position
		trap.global_rotation.y = trap_to_be_copied.global_rotation.y
		print("instantiated trap")
		
		
	
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and is_active == true:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$ScrollContainer.scroll_horizontal += 5
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$ScrollContainer.scroll_horizontal -= 5
