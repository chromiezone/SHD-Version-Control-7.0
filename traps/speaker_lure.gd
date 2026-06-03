class_name SpeakerLure extends Lure3D


@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var stream_length : float
var level : Node3D
var has_power : bool
var audio_position : float
var has_played_before := false
var current_playback : float

var burglar_lured := false
var lure_count := 0
var burglar : Burglar = null
var burglar_in_range := false

var is_active := false: set = set_is_active

func _init() -> void:
	trap_name = "SpeakerLure"
	cruelty_rating = Cruelty.HUMANE
	super()

func set_is_active(new_value) -> void:
	is_active = new_value
	if is_active == true and has_played_before == false:
		$AudioStreamPlayer3D.play(audio_position)
		$ButtonPress.play()
		has_played_before = true
		$speakerlure_mesh/PowerSwitch_001.rotation.z = -PI
	elif is_active == true and has_played_before == true:
		$AudioStreamPlayer3D.play(current_playback)
		$ButtonPress.play()
		$speakerlure_mesh/PowerSwitch_001.rotation.z = -PI
	else:
		$AudioStreamPlayer3D.stream_paused = true
		$ButtonPress.play()
		$speakerlure_mesh/PowerSwitch_001.rotation.z = 0

func _ready() -> void:
	stream_length = audio_stream_player_3d.stream.get_length()
	audio_position = randf_range(stream_length * 0.10, stream_length * 0.30)
	level = Globals.main_level
	if level != null:
		has_power = level.power_on
	$Interactable3D.interacted_with.connect(func()-> void:
		print("should turn on music")
		is_active = not is_active
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
			lure_count += 1
			get_tree().create_timer(5.0).timeout.connect(func() -> void:
				set_is_active(false)
				print("should turn off speaker")
				)
		)
	$HammerInteractable.connect("interacted_with_hammer", destroy)
	
func _physics_process(_delta: float) -> void:
	#print("burglar is " + str(burglar))
	if level != null:
		has_power = level.power_on
	current_playback = $AudioStreamPlayer3D.get_playback_position()
	
	
	if burglar != null and overlaps_body(burglar):
		burglar_in_range = true
		#print("burglar inside area")
	else:
		burglar_in_range = false
	
	if burglar:
		if not burglar._lure_interaction_cooldown.is_stopped() or lure_count >= 2:
			return
		if burglar_in_range == true and is_active == true and burglar.lure == null:
			burglar.lure = self
			print("should really lure")
			burglar.being_lured = true
			burglar_lured = true

func destroy() -> void:
	Globals.trap_count -= 1
	queue_free()
