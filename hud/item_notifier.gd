class_name ItemNotifier extends VFlowContainer

var texture_rect := TextureRect.new()
var text_label := RichTextLabel.new()
var item_node := HBoxContainer.new()


func _ready() -> void:
	add_to_group("ItemNotifier")
	child_entered_tree.connect(plan_deletion)
	alignment = FlowContainer.ALIGNMENT_END
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	texture_rect.texture = load(Globals.texture_placeholder)
	text_label.add_theme_font_size_override(&"normal_font_size", 45)
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_label.fit_content = true
	text_label.text = "placeholder"
	item_node.add_child(texture_rect)
	item_node.add_child(text_label)


func plan_deletion(node:Node) -> void:
	if node is not HBoxContainer: return
	await get_tree().create_timer(3).timeout
	var deletion_tween := create_tween()
	deletion_tween.tween_property(node, ^"modulate:a", 0, 1)
	deletion_tween.play()
	await deletion_tween.finished
	node.queue_free()


func add_item(item:Item) -> void:
	match item.type:
		Item.ItemType.WEAPON:
			texture_rect.texture = load(item.weapon_resource.hud)
			text_label.text = "+%d" % item.amount
		Item.ItemType.AMMO:
			texture_rect.texture = load(item.weapon_resource.hud)
			text_label.text = "+%d" % item.amount
		_:
			texture_rect.texture = load(item.sprite_image)
			text_label.text = "+%d" % item.amount
	add_child(item_node.duplicate())
