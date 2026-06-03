@tool
class_name Hitbox3D extends Area3D

## Emitted when the hitbox hits a hurtbox.
signal hit_hurt_box(hurtbox: Hurtbox3D)

const DAMAGE_SOURCE_PLAYER := 0b100
const DAMAGE_SOURCE_ENEMY := 0b010
const DAMAGE_SOURCE_TRAP := 0b001


@export var damage := 1
## Controls what the hitbox can hit.
@export_flags("Player", "Enemy", "Trap") var damage_source := DAMAGE_SOURCE_PLAYER: set = set_damage_source

func set_damage_source(new_value: int) -> void:
	damage_source = new_value
	collision_layer = damage_source

## Determines what can detect the hitbox.
@export_flags("Player", "Enemy", "Trap") var detected_hurtboxes := DAMAGE_SOURCE_ENEMY: set = set_detected_hurtboxes

func set_detected_hurtboxes(new_value: int) -> void:
	detected_hurtboxes = new_value
	collision_mask = detected_hurtboxes

func _init() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(func on_area_entered(area: Area3D) -> void:
		#print(area)
		if area is Hurtbox3D:
			hit_hurt_box.emit(area)
			#print("hitbox has hit hurtbox")
		)
	
