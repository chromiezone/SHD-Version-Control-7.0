@tool
class_name Hurtbox3D extends Area3D

## Emitted when the hurtbox detects a hitbox.
signal took_hit(hit_box: Hitbox3D)

const DAMAGE_SOURCE_PLAYER := 0b100
const DAMAGE_SOURCE_ENEMY := 0b010
const DAMAGE_SOURCE_TRAP := 0b001

## Controls what can hit the hurtbox.
@export_flags("Player", "Enemy", "Trap") var damage_source := DAMAGE_SOURCE_PLAYER: set = set_damage_source
## Determines what can detect the hurtbox.
@export_flags("Player", "Enemy", "Trap") var hurtbox_type := DAMAGE_SOURCE_ENEMY: set = set_hurtbox_type

func set_damage_source(new_value: int) -> void:
	damage_source = new_value
	collision_mask = damage_source

func set_hurtbox_type(new_value: int) -> void:
	hurtbox_type = new_value
	collision_layer = hurtbox_type

func _init() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(func _on_area_entered(area: Area3D) -> void:
		print(area)
		if area is Hitbox3D:
			took_hit.emit(area)
			print("hurtbox has been hit by hitbox")
		)
