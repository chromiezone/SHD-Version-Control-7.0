extends Area3D

var meets_prerequisites := false
var clipping := false

var trap_name := "GlueTrap"


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("attack"):
		rotation.x += 0.01
	if Input.is_action_pressed("right_click"):
		rotation.x -= 0.01
	
	
	if not has_overlapping_bodies():
		meets_prerequisites = false
	if has_overlapping_bodies():
		if get_overlapping_bodies().size() > 1:
			meets_prerequisites = false
		if get_overlapping_bodies().size() == 1:
			var body = get_overlapping_bodies().get(0)
			if body.collision_layer == 8192:
				meets_prerequisites = true
	
	# Prevents traps from being placed over eachother
	if has_overlapping_areas():
		var areas = get_overlapping_areas()
		for i in areas:
			if i is not Trap3D:
				continue
			elif i is Trap3D:
				meets_prerequisites = false
	
	
	#print($ClippingPreventionArea.get_overlapping_bodies())
	if $ClippingPreventionArea.has_overlapping_bodies():
		clipping = true
	else:
		clipping = false
	
	if clipping == true:
		meets_prerequisites = false
	
	if Globals.player.inventory["GlueTrap"] <= 0:
		meets_prerequisites = false
	
	if meets_prerequisites == true:
		for child in $gluetrap_mesh.get_children():
			if child is MeshInstance3D:
				child.set_surface_override_material(0, preload("res://traps/visuals/VisualGreen.tres"))
	else:
		for child in $gluetrap_mesh.get_children():
			if child is MeshInstance3D:
				child.set_surface_override_material(0, preload("res://traps/visuals/VisualRed.tres"))
