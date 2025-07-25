class_name Weapon extends Resource

enum WeaponType {
	NONE,
	MELEE,
	FIREARM,
	THROWABLE,
}

@export var weapon_name : String


@export_category("Ammo")
@export var ammo := 1
@export var max_ammo := 1
@export var magazine_size := 1
@export var current_magazine := 1

@export_category("Features")
@export var type := WeaponType.NONE
@export var damage := 1
@export var attack_time := 0.0
@export var projectile_speed := 25
@export_flags_3d_physics var collision_mask := 13

@export_category("Bitmaps")
@export_file var hud := Globals.texture_placeholder
@export_file var sprite := Globals.texture_placeholder
@export_file var sprite_attack := Globals.texture_placeholder

@export_file var sound := "uid://dbh60kyp43bdu"
@export_file var empty := "uid://bhflf1d44c3we"

@export_file var projectile := "uid://4nryh2m40sff"

var audio_player := AudioStreamPlayer.new()


func shoot() -> bool:
	if type != WeaponType.FIREARM: return false
	if current_magazine > 0:
		current_magazine -= 1
		spawn_projectile()
		play_sound()
		return true
	else: play_sound(empty)
	return false


func spawn_projectile() -> void:
	var player = Globals.get_player()
	if player == null: return
	var projectile_ := load(projectile)
	if projectile_ is not PackedScene: return
	if not (projectile_ as PackedScene).can_instantiate(): return
	var projectile_node := (projectile_ as PackedScene).instantiate()
	if projectile_node is not Projectile: return
	(projectile_node as Projectile).damage = damage
	(projectile_node as Projectile).collision_mask_ = collision_mask
	(projectile_node as Projectile).speed = projectile_speed
	(projectile_node as Projectile).velocity = -player.global_transform.basis.z.normalized()
	Globals.get_tree().current_scene.add_child(projectile_node)
	(projectile_node as Projectile).global_position = player.global_position
	(projectile_node as Projectile).global_rotation = player.global_rotation


func reload() -> void:
	if type != WeaponType.FIREARM: return
	var mag_delta := magazine_size - current_magazine
	if mag_delta <= 0: return
	var ammo_delta :=  ammo - mag_delta
	if ammo_delta <= 0:
		current_magazine += ammo
		ammo = 0
	else:
		current_magazine += mag_delta
		ammo -= mag_delta


func play_sound(stream:String=sound) -> void:
	if not audio_player.is_inside_tree(): 
		Globals.get_tree().current_scene.add_child(audio_player)
		audio_player.volume_db -= 10
		audio_player.set_bus(&"SFX")
	audio_player.stream = load(stream)
	audio_player.pitch_scale = randf_range(0.9, 1.1)
	audio_player.play()
