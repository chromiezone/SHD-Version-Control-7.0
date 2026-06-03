class_name Interactable3D extends Area3D

signal interacted_with

var can_interact : bool

func _init() -> void:
	monitoring = false
	can_interact = true

func interact() -> void:
	interacted_with.emit()
