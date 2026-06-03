class_name LootObject extends StaticBody3D

@export var looting_duration := 5.0
var is_looted := false

@onready var _burglar_detection_area: Area3D = %BurglarDetectionArea

func _ready() -> void:
	_burglar_detection_area.body_entered.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			body.is_looting = true
			body.looting_timer_node.start()
		)
