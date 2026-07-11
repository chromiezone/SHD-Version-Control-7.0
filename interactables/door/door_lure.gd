class_name DoorLure extends Lure3D

var burglar_lured := false
var burglar : Burglar = null
var burglar_in_range := false

var is_active := false: set = set_is_active



func set_is_active(new_value) -> void:
	is_active = new_value

func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			burglar = body
		#if body is Burglar and is_active == true and has_lured == false:
			#body.being_lured = true
			#burglar_lured = true
			#print("should lure")
	)
	body_entered.connect(func(body: Node3D) -> void:
		if body is Burglar and burglar_lured == true:
			has_lured = true
			get_tree().create_timer(5.0).timeout.connect(func() -> void:
				set_is_active(false)
				)
		)
	
func _physics_process(_delta: float) -> void:
	#print("burglar is " + str(burglar))
	
	
	if burglar != null and overlaps_body(burglar):
		burglar_in_range = true
		#print("burglar inside phone area") 
	else:
		burglar_in_range = false
	
	if burglar:
		if not burglar._lure_interaction_cooldown.is_stopped():
			return
		if burglar_in_range == true and is_active == true and has_lured == false and burglar.lure == null:
			burglar.lure = self
			print("should really lure")
			burglar.being_lured = true
			burglar_lured = true
