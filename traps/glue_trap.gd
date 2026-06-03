class_name GlueTrap extends Trap3D


var stake1_completion: int = 0
var stake2_completion: int = 0
var stake3_completion: int = 0
var stake4_completion: int = 0
var delete_completion := 0 : set = set_delete_completion


func set_delete_completion(new_value) -> void:
	delete_completion = new_value
	if new_value == 4:
		destroy()


func _init() -> void:
	trap_name = "GlueTrap"
	cruelty_rating = Cruelty.BARBARIC
	super()

func _ready() -> void:
	instant_death = true
	$HammerInteractable.connect("interacted_with_hammer", func() -> void:
		print("interacted with stake")
		stake1_completion += 1
		if stake1_completion == 2:
			$gluetrap_mesh/WoodenStake_002.hide()
			delete_completion += 1
		)
	$HammerInteractable2.connect("interacted_with_hammer", func() -> void:
		print("interacted with stake")
		stake2_completion += 1
		if stake2_completion == 2:
			$gluetrap_mesh/WoodenStake_003.hide()
			delete_completion += 1
		)
	$HammerInteractable3.connect("interacted_with_hammer", func() -> void:
		print("interacted with stake")
		stake3_completion += 1
		if stake3_completion == 2:
			$gluetrap_mesh/WoodenStake_001.hide()
			delete_completion += 1
		)
	$HammerInteractable4.connect("interacted_with_hammer", func() -> void:
		print("interacted with stake")
		stake4_completion += 1
		if stake4_completion == 2:
			$gluetrap_mesh/WoodenStake.hide()
			delete_completion += 1
		)
	
	
	# Player 
	body_entered.connect(func(body: Node3D) -> void:
		if body is PlayerFPSController:
			body.can_sprint = false
			body.max_speed_jog = 0.5
		)
	body_exited.connect(func(body: Node3D) -> void:
		if body is PlayerFPSController:
			body.can_sprint = true
			body.max_speed_jog = 4.0
			
		)
	# Burglar
	body_entered.connect(func(body: Node3D) -> void:
		if body is Burglar:
			body.walk_speed = 0.5
		)
	body_exited.connect(func(body: Node3D) -> void:
		if body is Burglar:
			body.walk_speed = 2.0
		)

func destroy() -> void:
	Globals.trap_count -= 1
	queue_free()
