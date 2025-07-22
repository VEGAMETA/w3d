extends Node


var lives : int = 1:
	set(v):
		lives = v
		get_tree().get_first_node_in_group("Lives").set_text("%d" % v)
		if lives <= 0: game_over()
var game_over_scene : String = "uid://06urf5hkgx4e"

var score : int = 0:
	set(v):
		score = v
		get_tree().get_first_node_in_group("Score").set_text("%06d" % v)
		

var buffer : String = ""


func _input(event:InputEvent) -> void:
	if event.is_action_pressed("Fullscreen"):
		if get_window().mode == Window.MODE_FULLSCREEN: get_window().mode = Window.MODE_WINDOWED
		else: get_window().mode = Window.MODE_FULLSCREEN
	if event is InputEventKey: key_stream(event as InputEventKey)


func key_stream(event:InputEventKey) -> void:
	if not event.is_pressed(): return
	var str_key = event.as_text_key_label()
	if str_key.contains("+") or str_key.contains("Alt") or str_key.contains("Space"): return
	buffer += str_key
	while buffer.length() > 5:
		buffer = buffer.erase(0)
		check_cheat()


func check_cheat() -> void:
	var player = get_player()
	if player == null: return
	match buffer:
		"IDDQD": player.invinsibility = !player.invinsibility
		_: return
	get_player().hud.blink(Color.BLACK)


func get_player() -> Player:
	return get_tree().get_first_node_in_group("Player")


func game_over() -> void:
	get_tree().change_scene_to_file.call_deferred(game_over_scene)


func get_item_by_needs() -> Item:
	var player := get_player()
	var needs : Array[Item]
	if player == null: return
	if player.health < 35:
		var heal_scene := load("uid://c8l7dqk0q671m") as PackedScene
		if heal_scene.can_instantiate():
			var heal := heal_scene.instantiate() as Item
			heal.amount = max(5, 35 - (player.health >> 1))
			needs.append(heal)
	for weapon in player.inventory:
		if weapon.ammo < weapon.max_ammo >> 1:
			var item_weapon = Item.new()
			item_weapon.type = Item.ItemType.WEAPON
			item_weapon.amount = randi_range(weapon.magazine_size >> 1, int(weapon.magazine_size * 1.5))
			item_weapon.sprite_image = weapon.hud
			item_weapon.weapon_resource = weapon.duplicate()
			needs.append(item_weapon)
	if randf() < 0.1:
		var treasure_scene := load("uid://c8tujvq80illk") as PackedScene
		if treasure_scene.can_instantiate():
			var treasure = treasure_scene.instantiate() as Item
			treasure.amount = 10000
			needs.append(treasure)
	if needs.is_empty(): return null
	var item : Item = needs.pick_random()
	if item == null: return null
	get_tree().current_scene.add_child(item)
	return item
