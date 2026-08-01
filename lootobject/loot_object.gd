class_name LootObject extends StaticBody3D

@export var looting_duration := 5.0
var is_looted := false
var occupancy_slots : int = 0 : set = set_occupancy_slots
var priority_list : Array = []

func set_occupancy_slots(new_value) -> void:
	if occupancy_slots == new_value:
		return
	if occupancy_slots != new_value:
		pass

@onready var _burglar_detection_area: Area3D = %BurglarDetectionArea

func _ready() -> void:
	_burglar_detection_area.body_entered.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			occupancy_slots += 1
			priority_list.append(body)
			body.is_looting = true
			body.looting_timer_node.start()
		)
	_burglar_detection_area.body_exited.connect(func(body: Node3D) -> void:
		if body is Enemy3D:
			occupancy_slots -= 1
			priority_list.erase(body)
		)
