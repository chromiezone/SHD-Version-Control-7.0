class_name DoorTorchM extends DoorTrap


func _init() -> void:
	trap_name = "DoorTorchM"
	super()
	cruelty_rating = Cruelty.SADISTIC
	instant_death = true
	electric_powered = false

func set_in_effect(new_value: bool) -> void:
	if in_effect == new_value:
		return
	in_effect = new_value
	if in_effect == true:
		$BlowTorchFlame/GPUParticles3D.emitting = true
		$BlowTorchFlame/GPUParticles3D/OmniLight3D/Timer.start()
		$BlowTorchFlame/GPUParticles3D/OmniLight3D.show()
		$blowtorch/Pulley/DoorRopeLink.hide()
		door_trap_in_effect.emit()
		$Hitbox3D/CollisionShape3D.set_deferred("disabled", false)
		Globals.trap_count -= 1
		get_tree().create_timer(15.0).timeout.connect(func() -> void:
			$BlowTorchFlame/GPUParticles3D.emitting = false
			destroy()
			)

func _ready() -> void:
	$Timer.timeout.connect(func() -> void:
		$Hitbox3D/CollisionShape3D.set_deferred("disabled", not $Hitbox3D/CollisionShape3D.disabled)
		)
	level = Globals.main_level
	#has_power = level.power_on
	$Hitbox3D/CollisionShape3D.disabled = true
	tamper_chance = 101
	$HammerInteractable.connect("interacted_with_hammer", destroy)



func _physics_process(_delta: float) -> void:
	
	pass
	if $DoorDetection.is_colliding():
			in_effect = true
			$Timer.start()
	
	

func destroy() -> void:
	queue_free()
	Globals.trap_count -= 1
