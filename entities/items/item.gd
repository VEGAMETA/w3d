@tool
class_name Item extends Area3D

enum ItemType {
	NONE, WEAPON, HEAL, BONUS, AMMO
}

static var ItemColor : Dictionary = {
	ItemType.NONE: Color.BLACK,
	ItemType.WEAPON: Color.CORNFLOWER_BLUE,
	ItemType.HEAL: Color.RED,
	ItemType.BONUS: Color.YELLOW,
	ItemType.AMMO: Color.CHARTREUSE,
}

@export var type : ItemType = ItemType.NONE
@export var amount : int = 0
@export var weapon_resource : Weapon
@export_file var sprite_image : String = Globals.texture_placeholder
var sprite := Sprite3D.new()
var collision_shape := CollisionShape3D.new()
var sphere_shape := SphereShape3D.new()
var light := OmniLight3D.new()

func _ready() -> void:
	collision_mask = 2
	body_entered.connect(consume)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.texture = load(sprite_image)
	sphere_shape.set_radius(0.125)
	collision_shape.set_shape(sphere_shape)
	light.light_color = ItemColor[type]
	light.light_energy = 0.1
	add_child(sprite)
	add_child(collision_shape)
	add_child(light)


func consume(body:Node3D) -> void:
	if body is not Player: return
	if body.pick_up(self): 
		body.picked_up(type)
		Globals.notify_item(self)
		queue_free()
