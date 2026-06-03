class_name NailboardTrap extends Trap3D

func _init() -> void:
	trap_name = "Nailboard"
	cruelty_rating = Cruelty.JUSTIFIABLE
	super()

func _ready() -> void:
	$Initialization.play()
	$Hitbox3D.body_entered.connect(func(_body: Node3D) -> void:
		destroy()
		)
	$Hitbox3D.area_entered.connect(func(area: Area3D) -> void:
		if area is Hurtbox3D and area.get_parent() is Enemy3D:
			var enemy = area.get_parent()
			var nailboard_index = enemy.interacted_with_trap.find("Nailboard")
			var nailboard_dictionary = enemy.interacted_with_trap[nailboard_index]
			nailboard_dictionary["times_interacted_with"] += 1
		)
	$HammerInteractable.connect("interacted_with_hammer", destroy)

func destroy() -> void:
	Globals.trap_count -= 1
	queue_free()
	
