extends OmniLight3D

func _ready() -> void:
	$Timer.wait_time = 0.08
	$Timer.timeout.connect(func() -> void:
		light_energy = randf_range(0.5, 1.0)
		)

#func _process(delta: float) -> void:
	#$Timer.wait_time = randf_range(0.08, 0.12)
