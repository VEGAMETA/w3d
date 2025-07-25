class_name HUD extends Control

signal weapon_hide
signal weapon_show

var weapon_hidden := false
var tween : Tween

var blink_tween: Tween

@onready var health: Label = %Health
@onready var ammo: Label = %Ammo
@onready var weapon_hud: TextureRect = %WeaponHud
@onready var weapon_sprite: TextureRect = %Weapon
@onready var blink_rect: ColorRect = %Blink

func blink(col:Color) -> void:
	blink_rect.color = col
	blink_tween = create_tween()
	blink_tween.tween_property(blink_rect, ^"color:a", 0.3, 0.4)
	blink_tween.finished.connect(unblink)

func unblink() -> void:
	blink_tween = create_tween()
	blink_tween.tween_property(blink_rect, ^"color:a", 0.0, 0.4)
	

func set_hud(player:Player) -> void:
	set_ammo(player.weapon)
	set_health(player.health)

func set_health(value:int) -> void:
	health.text = "%d" % value

func set_ammo(weapon:Weapon) -> void:
	if weapon == null: return
	ammo.text = "%d/%d" % [weapon.current_magazine, weapon.ammo]
	weapon_hud.texture = load(weapon.hud)
	weapon_sprite.texture = load(weapon.sprite)

func attack_ammo(weapon:Weapon) -> void:
	if weapon == null: return
	weapon_sprite.texture = load(weapon.sprite_attack)

func hide_weapon(time:float=0.5) -> void:
	tween = create_tween()
	tween.tween_property(weapon_sprite, ^"position:y", 535, time)
	tween.play()
	tween.finished.connect(show_weapon.bind(time))
	weapon_hidden = true

func show_weapon(time:float=0.5) -> void:
	weapon_hide.emit()
	tween = create_tween()
	tween.tween_property(weapon_sprite, ^"position:y", 245, time)
	tween.play()
	tween.finished.connect(
		func () -> void: 
			weapon_hidden = false
			weapon_show.emit()
	)
