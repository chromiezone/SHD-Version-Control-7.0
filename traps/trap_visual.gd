class_name FixedTrapVisual extends Interactable3D


func _init() -> void:
	can_interact = false

func interact() -> void:
	super()
	print("attempting to place trap")

class Blackboard extends RefCounted:
	static var trap_menu_open := false
