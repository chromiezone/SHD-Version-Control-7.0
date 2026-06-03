class_name GooningLure extends Lure3D

var level : Node3D

var burglar_lured := false
var burglar : Burglar = null
var burglar_in_range := false

var is_active := false: set = set_is_active

@onready var _decal: Decal = $Decal
@onready var _audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _init() -> void:
	trap_name = "GooningLure"
	cruelty_rating = Cruelty.HUMANE
	super()

func set_is_active(new_value) -> void:
	is_active = new_value

func decal_tween() -> void:
	var tween = create_tween()
	var decal_1 = preload("res://traps/textures/gooninglure/gooningluredecal1.png")
	var decal_2 = preload("res://traps/textures/gooninglure/gooningluredecal2.png")
	tween.set_loops(30)
	tween.tween_property(_decal, "texture_albedo", decal_2, 0.20)
	tween.tween_property(_decal, "texture_albedo", decal_1, 0.20)
	tween.finished.connect(func() -> void:
		$Decal.hide()
		$AudioStreamPlayer3D.stop()
		$OmniLight3D.hide()
		$EmissiveMesh.hide()
		is_active = false
		)

func _ready() -> void:
	level = Globals.main_level
	$Interactable3D.interacted_with.connect(func()-> void:
		$Interactable3D.can_interact = false
		$OmniLight3D.show()
		$Decal.show()
		$AudioStreamPlayer3D.play()
		$EmissiveMesh.show()
		decal_tween()
		is_active = true
		)
	
	body_entered.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			burglar = body
		#if body is Burglar and is_active == true and has_lured == false:
			#body.being_lured = true
			#burglar_lured = true
			#print("should lure")
	)
	$LuredArea.body_entered.connect(func(body: Node3D) -> void:
		if body is Burglar and burglar_lured == true:
			has_lured = true
			get_tree().create_timer(5.0).timeout.connect(func() -> void:
				set_is_active(false)
				print("should turn off phone")
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
