class_name DoorTrap extends Trap3D

signal door_trap_in_effect

var in_effect := false : set = set_in_effect
var level : Node3D
var has_power : bool

func _init() -> void:
	trap_name = "DoorBombE"
	super()
	cruelty_rating = Cruelty.HUMANE
	instant_death = true
	electric_powered = true

func set_in_effect(new_value: bool) -> void:
	if in_effect == new_value:
		return
	in_effect = new_value
	if in_effect == true:
		door_trap_in_effect.emit()
		$Hitbox3D/CollisionShape3D.set_deferred("disabled", false)
		Globals.trap_count -= 1
		explosion_sound()
		get_tree().create_timer(0.5).timeout.connect(queue_free)

func _ready() -> void:
	level = Globals.main_level
	has_power = level.power_on
	$Hitbox3D/CollisionShape3D.disabled = true
	tamper_chance = 101
	$Initialization.play()
	$HammerInteractable.connect("interacted_with_hammer", destroy)



func _physics_process(_delta: float) -> void:
	has_power = level.power_on
	
	if $Laser.is_colliding() and has_power:
		in_effect = true
	
	

func explosion_sound() -> void:
	var explosion = AudioStreamPlayer3D.new()
	explosion.stream = preload("res://traps/sfx/523089__magnuswaker__explosion-1.wav")
	explosion.volume_db = 50.0
	add_sibling(explosion)
	explosion.play()
	explosion.finished.connect(explosion.queue_free)

func destroy() -> void:
	queue_free()
	Globals.trap_count -= 1
