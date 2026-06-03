class_name BearTrap extends Trap3D

var _bear_trap_tween : Tween = null
@onready var jaw_1_rotation_point: Marker3D = $bear_trap_mesh/Jaw1RotationPoint
@onready var jaw_2_rotation_point: Marker3D = $bear_trap_mesh/Jaw2RotationPoint



func _init() -> void:
	trap_name = "BearTrap"
	cruelty_rating = Cruelty.BARBARIC
	super()

func _ready() -> void:
	instant_death = true
	$Initialization.play()
	$Hitbox3D.body_entered.connect(func(_body: Node3D) -> void:
		$TrapActivated.play()
		await get_tree().create_timer(0.1).timeout
		bear_trap_tween()
		)
	$Hitbox3D.area_entered.connect(func(area: Area3D) -> void:
		if area is Hurtbox3D and area.get_parent() is Enemy3D:
			var enemy = area.get_parent()
			var beartrap_index = enemy.interacted_with_trap.find("BearTrap")
			var beartrap_dictionary = enemy.interacted_with_trap[beartrap_index]
			beartrap_dictionary["times_interacted_with"] += 1
		)
	$HammerInteractable.connect("interacted_with_hammer", destroy)

func bear_trap_tween() -> void:
	if _bear_trap_tween != null:
		_bear_trap_tween.kill()
	_bear_trap_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SPRING)
	_bear_trap_tween.tween_property(jaw_1_rotation_point, "rotation:z",  PI / 2.0, 0.1)
	_bear_trap_tween.tween_property(jaw_2_rotation_point, "rotation:z", - PI / 2.0, 0.1)
	_bear_trap_tween.finished.connect(func() -> void:
		$Hitbox3D/CollisionShape3D.disabled = true
		get_tree().create_timer(5.0).timeout.connect(destroy)
		)

func destroy() -> void:
	Globals.trap_count -= 1
	queue_free()
	
