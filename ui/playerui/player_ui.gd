class_name PlayerUI extends Control

var is_active := false: set = set_is_active
@onready var money_label: Label = $VBoxContainer/MoneyLabel

@onready var weapons_icon: TextureRect = $VBoxContainer2/WeaponsIcon
var weapon_texture: Texture : set = set_weapon_texture

@onready var trap_icon: TextureRect = $VBoxContainer2/TrapIcon
var trap_texture: Texture : set = set_trap_texture

@onready var health_icon: TextureRect = $VBoxContainer2/HealthIcon
var health_texture: Texture : set = set_health_texture

var player : PlayerFPSController = null
var player_weapon = null

func set_is_active(new_value: bool) -> void:
	is_active = new_value

func set_weapon_texture(new_texture: Texture) -> void:
	weapon_texture = new_texture
	weapons_icon.texture = new_texture

func set_trap_texture(new_texture: Texture) -> void:
	trap_texture = new_texture
	trap_icon.texture = new_texture

func set_health_texture(new_texture: Texture) -> void:
	health_texture = new_texture
	health_icon.texture = new_texture

func _ready() -> void:
	set_is_active(is_active)
	player = Globals.player
	set_weapon_texture(preload("res://ui/playerui/icons/itemiconempty.png"))
	set_trap_texture(preload("res://ui/playerui/icons/itemiconempty.png"))
	set_health_texture(preload("res://ui/playerui/icons/healthicon100crop.png"))
	

func _process(_delta: float) -> void:
	
	if player.fists_up == true:
		set_weapon_texture(preload("res://weapons/icons/fistsweaponicon2.png"))
	elif player.hammer_up == true:
		set_weapon_texture(preload("res://weapons/icons/hammerweaponicon.png"))
	else:
		set_weapon_texture(preload("res://ui/playerui/icons/itemiconempty.png"))
	
	
	
	
	match player.selected_trap:
		null:
			set_trap_texture(preload("res://ui/playerui/icons/itemiconempty.png"))
		"Nailboard":
			set_trap_texture(preload("res://traps/icons/nailboard.png"))
		
	match player.selected_fixed_trap:
		"DoorBombE":
			set_trap_texture(preload("res://traps/icons/electricdoorbombcrop.png"))
		"DoorTorchM":
			set_trap_texture(preload("res://traps/icons/doortorchm.png"))
	
	var health_percentage = player.health / float(player.max_health) * 100
	if health_percentage == 100:
		set_health_texture(preload("res://ui/playerui/icons/healthicon100crop.png"))
	elif health_percentage <= 80 and health_percentage > 61:
		set_health_texture(preload("res://ui/playerui/icons/healthicon80crop.png"))
	elif health_percentage <= 60 and health_percentage > 41:
		set_health_texture(preload("res://ui/playerui/icons/healthicon60crop.png"))
	elif health_percentage <= 40 and health_percentage > 21:
		set_health_texture(preload("res://ui/playerui/icons/healthicon40crop.png"))
	elif health_percentage <= 20 and health_percentage >= 1:
		set_health_texture(preload("res://ui/playerui/icons/healthicon20crop.png"))
	elif health_percentage == 0:
		set_health_texture(preload("res://ui/playerui/icons/healthicon0crop.png"))
