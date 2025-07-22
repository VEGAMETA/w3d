class_name Player extends CharacterBody3D

const SPEED := 500.0
const ROTATION_SPEED := 4.0
const MAX_HEALTH := 100

var mouse_sens := 0.4

var walk := 0.0
var strafe := 0.0
var turn := 0.0

var invinsibility := false

var health := MAX_HEALTH:
	set(v):
		if invinsibility: return
		health = v
		hud.set_health(health)
		if health <= 0: 
			Globals.lives -= 1
			health = MAX_HEALTH

var inventory : Array[Weapon]
var weapon : Weapon

@onready var attack_timer : Timer = %AttackTimer
@onready var hud : HUD = %Hud
@onready var colse_range : Area3D = %CloseRangeArea
@onready var audio_hit : AudioStreamPlayer = %Hit
@onready var audio_walk : AudioStreamPlayer = %Walk
@onready var audio_area: Area3D = %AudioArea
@onready var audio_range: CollisionShape3D = %AudioRange
@onready var audio_heal: AudioStreamPlayer = %Heal
@onready var audio_pick_up_treasure: AudioStreamPlayer = %PickUpTreasure
@onready var audio_pick_up_gun: AudioStreamPlayer = %PickUpGun
@onready var audio_pick_up_ammo: AudioStreamPlayer = %PickUpAmmo
@onready var audio_pick_up_heal: AudioStreamPlayer = %PickUpHeal


func _ready() -> void:
	add_to_group("Player")
	inventory.append(load("uid://bppivivsugigy") as Weapon)
	attack_timer.timeout.connect(attacked)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	weapon = inventory.get(0)
	hud.set_ammo(weapon)
	hud.weapon_show.connect(
		func () -> void:
			weapon.reload()
			hud.set_ammo(weapon)
	)


func _input(event:InputEvent) -> void:
	if event.is_action_pressed("Attack"): attack()
	if event.is_action_pressed("Reload"): reload()
	if event.is_action_pressed("SwitchUp"): swtch_weapon(false)
	if event.is_action_pressed("SwitchDown"): swtch_weapon(true)


func _unhandled_input(event:InputEvent) -> void:
	walk = Input.get_axis("Forward", "Backward")
	turn = Input.get_axis("Right", "Left")
	# HUD(control) Must have ignored mouse property
	if event is InputEventMouseMotion and not Input.is_action_pressed("StrafeControl"):
		var mouse_speed = (event as InputEventMouseMotion).relative.normalized()
		walk = mouse_speed.y
		turn = -mouse_speed.x * mouse_sens
		clear_inputs.call_deferred()


func _unhandled_unhandled_input() -> void:
	if not Input.is_action_pressed("StrafeControl"): return
	var mouse_speed := Input.get_last_mouse_velocity().normalized() * 1.2
	walk = mouse_speed.y
	strafe = mouse_speed.x
	clear_inputs.call_deferred()


func _physics_process(delta:float) -> void:
	_unhandled_unhandled_input()
	velocity = transform.basis.z * walk * delta * SPEED
	velocity += transform.basis.x * strafe * delta * SPEED
	global_rotation.y += turn * delta * ROTATION_SPEED
	if velocity.length() > 4.0 and \
		(audio_walk.get_playback_position() > 0.45 or \
		audio_walk.get_playback_position() == 0.0): 
			play(audio_walk, randf_range(0.9, 1.1), 1.4)
	move_and_slide()


func clear_inputs() -> void:
	turn = 0
	walk = 0
	strafe = 0


func attack() -> void:
	if hud.weapon_hidden: return
	if weapon == null: return
	if not attack_timer.is_stopped(): return
	match weapon.type:
		Weapon.WeaponType.MELEE: melee_attack(weapon.damage)
		Weapon.WeaponType.FIREARM: if not weapon.shoot(): return
	attack_timer.start(weapon.attack_time)
	hud.attack_ammo(weapon)


func attacked() -> void:
	if weapon == null: return
	hud.set_ammo(weapon)


func hit(damage) -> void:
	health = max(0, health - damage)
	hud.blink(Color.WEB_MAROON)
	play(audio_hit)


func heal(value:int) -> bool:
	if health == MAX_HEALTH: return false
	health = min(MAX_HEALTH, health + value)
	if value >= 5: audio_heal.play()
	return true


func pick_up(item: Item) -> bool:
	match item.type:
		Item.ItemType.BONUS: Globals.score += item.amount
		Item.ItemType.HEAL: return heal(item.amount)
		Item.ItemType.AMMO:
			var new_weapon : Weapon = item.weapon_resource
			for w in inventory:
				if w.weapon_name != new_weapon.weapon_name: continue
				var max_ammo = w.max_ammo + w.magazine_size - w.current_magazine
				if w.ammo >= max_ammo: return false
				w.ammo = min(max_ammo, w.ammo + item.amount)
				if w == weapon: hud.set_ammo(w)
				return true
			return false
		Item.ItemType.WEAPON:
			var new_weapon : Weapon = item.weapon_resource
			for w in inventory:
				if w.weapon_name != new_weapon.weapon_name: continue
				var max_ammo = w.max_ammo + w.magazine_size - w.current_magazine
				if w.ammo >= max_ammo: return false
				w.ammo = min(max_ammo, w.ammo + item.amount)
				if w == weapon: hud.set_ammo(w)
				return true
			new_weapon.current_magazine = 0
			new_weapon.ammo = min(new_weapon.max_ammo + new_weapon.magazine_size, item.amount)
			new_weapon.reload()
			inventory.append(new_weapon)
			weapon = new_weapon
			hud.hide_weapon()
			hud.weapon_hide.connect(func () -> void: hud.set_ammo(new_weapon))
	return true


func picked_up(type:Item.ItemType) -> void:
	match type:
		Item.ItemType.HEAL: hud.blink(Color.CHARTREUSE); audio_pick_up_heal.play()
		Item.ItemType.BONUS: hud.blink(Color.NAVY_BLUE); audio_pick_up_treasure.play()
		Item.ItemType.AMMO: hud.blink(Color.GOLD); audio_pick_up_ammo.play()
		Item.ItemType.WEAPON: hud.blink(Color.DARK_GOLDENROD); audio_pick_up_gun.play()


func melee_attack(damage:int) -> void:
	for body in colse_range.get_overlapping_bodies():
		if body is not Enemy: continue
		(body as Enemy).hit(damage)
		weapon.play_sound()


func reload() -> void:
	if weapon.type != Weapon.WeaponType.FIREARM: return
	if weapon.current_magazine == weapon.magazine_size: return
	if weapon.ammo == 0: return
	hud.hide_weapon()
	if weapon == null: return


func swtch_weapon(direction:bool=true) -> void:
	if hud.weapon_hidden: return
	if not attack_timer.is_stopped(): return
	if direction: inventory.append(inventory.pop_front())
	else: inventory.insert(0, inventory.pop_back())
	weapon = inventory.get(0)
	if weapon == null: return
	hud.hide_weapon()
	hud.weapon_hide.connect(func () -> void: hud.set_ammo(weapon))
	hud.weapon_show.connect(func () -> void: return)


func play(audio: AudioStreamPlayer, pitch:float=randf_range(0.9, 1.1), radius:float=4.0, alert=true) -> void:
	if alert:
		(audio_range.shape as SphereShape3D).set_radius(radius)
		audio_area.force_update_transform()
		for body : Node3D in audio_area.get_overlapping_bodies():
			if not body.has_method(&"alert"): continue
			body.alert()
	audio.pitch_scale = pitch
	audio.play()
