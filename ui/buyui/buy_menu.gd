class_name BuyMenu extends Control

@onready var _item_list: ItemList = $ItemList
@onready var buy_button: Button = $BuyButton
@onready var price_label: Label = $PriceLabel

var is_active := false: set = set_is_active

var trap_entries := [
	{"item_name": "DoorBombE", "price" : 350},
	{"item_name": "Nailboard", "price" : 10},
	{"item_name": "BearTrap", "price" : 450},
	{"item_name": "DoorTorchM", "price" : 100},
	{"item_name": "GlueTrap", "price" : 150},
	{"item_name": "SpeakerLure", "price" : 400}
	,
]
var player : PlayerFPSController = null
var terminal : Terminal = null

var selected_items_array := []
var selected_item = null

func set_is_active(new_value: bool) -> void:
	is_active = new_value
	visible = is_active

func _unhandled_input(_event: InputEvent) -> void:
	if terminal:
		if is_active == true and player._interaction_ray_cast_3d.get_collider() is Terminal:
			print("menu opened")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif is_active == false and player._interaction_ray_cast_3d.get_collider() is Terminal:
			print("menu closed")
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	set_is_active(is_active)
	_item_list.item_selected.connect(_on_item_selected)
	buy_button.pressed.connect(func() -> void:
		if player != null:
			var added_trap_name = trap_entries[selected_item]["item_name"]
			if Globals.player_money >= trap_entries[selected_item]["price"]:
				Globals.player_money -= trap_entries[selected_item]["price"]
				player.inventory[str(added_trap_name)] += 1
				print("bought trap")
		)


func _on_item_selected(_index: int) -> void:
	selected_items_array = _item_list.get_selected_items()
	selected_item = selected_items_array[0]
	print(selected_item)
	price_label.text = "$" + str(trap_entries[selected_item]["price"])
	
