extends Area3D

var meets_prerequisites := false

var trap_name := "Nailboard"


func _physics_process(_delta: float) -> void:
	
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
	
	if Globals.player.inventory["Nailboard"] <= 0:
		meets_prerequisites = false
	
	if meets_prerequisites == true:
		for child in $NailboardMesh.get_children():
			child.set_surface_override_material(0, preload("res://traps/visuals/VisualGreen.tres"))
		$Nailboard.set_surface_override_material(0, preload("res://traps/visuals/VisualGreen.tres"))
		for child in $Nailboard.get_children():
			child.set_surface_override_material(0, preload("res://traps/visuals/VisualGreen.tres"))
	else:
		for child in $NailboardMesh.get_children():
			child.set_surface_override_material(0, preload("res://traps/visuals/VisualRed.tres"))
		$Nailboard.set_surface_override_material(0, preload("res://traps/visuals/VisualRed.tres"))
		for child in $Nailboard.get_children():
			child.set_surface_override_material(0, preload("res://traps/visuals/VisualRed.tres"))
