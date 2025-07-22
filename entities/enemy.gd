class_name Enemy extends CharacterBody3D

const SPEED : float = 3.0
const ANIMATION_SPEED : float = 5.0

enum EnemyState {
	DEAD, DYING, IDLE, WALK, ATTACK, DAMAGED, ALERT
}

enum Directions {
	 DOWN, LEFT_DOWN, LEFT,  LEFT_UP, UP, RIGHT_UP, RIGHT, RIGHT_DOWN
}

var health := 100:
	set(v):
		if v <= 0: die()
		health = v
var damage := 3
var state := EnemyState.IDLE

var direction : Vector3
var angle : float = 0.0
var step : float = 0.0
var searching : bool = false : 
	set(v):
		if v: patroling = false
		searching = true
var patroling : bool = true
var seen_player : bool = false
var player_in_radius : bool = false
var player : Player

var route : Array[Vector3]

@export var path : Path3D 

@export_file var drop_item : String

@onready var nav_agent : NavigationAgent3D = %NavAgent
@onready var attack_cooldown : Timer = %AttackCooldown
@onready var patrol_timer : Timer = %PatrolTimer
@onready var sprite : AnimatedSprite3D = %Sprite
@onready var view_zone : Area3D = %ViewZone
@onready var view_zone_radius : RayCast3D = %Radius
@onready var aim : RayCast3D = %Aim

@onready var audio_damaged : AudioStreamPlayer3D = %Damaged
@onready var audio_shoot : AudioStreamPlayer3D = %Shoot
@onready var audio_step : AudioStreamPlayer3D = %Step
@onready var audio_range: CollisionShape3D = %AudioRange
@onready var audio_halt: AudioStreamPlayer3D = %Halt
@onready var audio_area: Area3D = %AudioArea

@onready var bullet : Bullet = %Bullet


func _ready() -> void:
	(func () -> void: player = Globals.get_player()).call_deferred()
	route.append_array(path.curve.get_baked_points() if path != null else PackedVector3Array([global_position]))
	set_state(EnemyState.IDLE)
	nav_agent.set_target_position(route.get(0))
	nav_agent.velocity_computed.connect(func (speed:Vector3) -> void: velocity = speed)
	patrol_timer.timeout.connect(next_patrol_point)
	sprite.animation_looped.connect(find_player)
	view_zone.body_entered.connect(func (body:Node3D): player_in_radius = true)
	view_zone.body_exited.connect(func (body:Node3D): player_in_radius = false)

func find_in_radius() -> void:
	if not player_in_radius: return
	view_zone_radius.look_at(player.global_position)
	view_zone_radius.force_update_transform()
	view_zone_radius.force_raycast_update()
	if view_zone_radius.get_collider() == player:
		searching = false
		if not seen_player: alert()
		else: attack()

	

func _physics_process(delta:float) -> void:
	if state == EnemyState.DYING or state == EnemyState.DEAD: return
	if player == null: return
	direction = (player.global_position - global_position).normalized()
	angle = atan2(direction.x, direction.z) - global_rotation.y
	angle = floor(wrap(angle * 4 / PI + 4.5, 0, 8))
	find_in_radius()
	if aim.get_collider() == player: 
		velocity = Vector3.ZERO
		searching = false
		if not seen_player: alert(false)
		elif state not in [EnemyState.ALERT, EnemyState.DAMAGED] : attack()
	match state:
		EnemyState.IDLE: sprite.set_frame(int(angle))
		EnemyState.WALK:
			sprite.set_frame(int(angle + floor(step) * 8))
			step = wrap(step + delta * ANIMATION_SPEED, 0, 4)
			if floor(step) == 2: play(audio_step, randf_range(0.9, 1.1), 4.0, false)
		EnemyState.ATTACK: spawn_bullet()
	if searching: search_player()
	elif patroling: patrol()
	if velocity != Vector3.ZERO: global_rotation.y = atan2(-velocity.x, -velocity.z)
	move_and_slide()


func search_player() -> void:
	nav_agent.set_target_position(player.global_position)
	nav_agent.set_velocity((nav_agent.get_next_path_position() - global_position).normalized() * 3)

func patrol() -> void:
	var current_point : Vector3 = route.get(0)
	if patrol_timer.is_stopped() and (global_position - current_point).length() < 1:
		set_state(EnemyState.IDLE)
		patrol_timer.start()
	nav_agent.set_velocity((nav_agent.get_next_path_position() - global_position).normalized() * 3)


func next_patrol_point() -> void:
	if not patroling: return
	if state != EnemyState.IDLE: return
	if route.size() == 1: return
	set_state(EnemyState.WALK)
	route.push_back(route.pop_front())
	nav_agent.set_target_position(route.get(0))


func set_state(new_state:EnemyState) -> void:
	state = new_state
	sprite.set_animation((EnemyState.find_key(state) as String).to_lower())
	if state in [EnemyState.IDLE, EnemyState.WALK]: sprite.set_frame(int(angle))
	else: patroling = false


func look_at_player() -> void:
	if player == null: return
	look_at(player.global_position, Vector3.UP) 


func hit(value:int) -> void:
	if state <= EnemyState.DYING: return
	searching = true
	set_state(EnemyState.DAMAGED)
	sprite.play()
	play(audio_damaged, randf_range(0.5, 0.7))
	health -= value


func find_player(body:Node3D=null) -> void:
	if body != null and body is not Player: return
	look_at_player()
	aim.force_update_transform()
	aim.force_raycast_update()
	if aim.get_collider() == player:
		searching = false
		if not seen_player: alert()
		else: attack()
	else: 
		searching = true
		set_state(EnemyState.WALK)


func alert(must_patrol:bool=not patroling) -> void:
	if seen_player: return
	if must_patrol: return
	seen_player = true
	set_state(EnemyState.ALERT)
	sprite.play()
	if not audio_halt.playing: play(audio_halt)


func attack() -> void:
	set_state(EnemyState.ATTACK)
	sprite.play()


func spawn_bullet() -> void:
	if not attack_cooldown.is_stopped(): return
	attack_cooldown.start()
	var _bullet : Bullet = bullet.duplicate()
	_bullet.set_physics_process(true)
	_bullet.set_process(true)
	_bullet.visible = true
	add_child(_bullet)
	_bullet.position.x += 0.1
	_bullet.global_position = global_position
	_bullet.global_rotation = global_rotation
	_bullet.velocity = ((
		player.global_position - global_position + \
		Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))\
	)).normalized()
	_bullet.speed = 25
	play(audio_shoot, randf_range(1.0, 1.4))


func die() -> void:
	set_state(EnemyState.DYING)
	sprite.play()
	sprite.animation_looped.connect(died)
	bullet.queue_free()


func died() -> void:
	sprite.stop()
	set_state(EnemyState.DEAD)
	collision_layer = 0
	set_physics_process(false)
	set_process(false)
	spawn_item()


func play(audio: AudioStreamPlayer3D, pitch:float=randf_range(0.9, 1.1), radius:float=4.0, alert_:bool=true) -> void:
	if alert_:
		(audio_range.shape as SphereShape3D).set_radius(radius)
		audio_area.force_update_transform()
		for body : Node3D in audio_area.get_overlapping_bodies():
			if not body.has_method(&"alert"): continue
			body.alert()
	audio.pitch_scale = pitch
	audio.play()


func spawn_item() -> void:
	var item: Item
	if drop_item:
		var item_scene := load(drop_item) as PackedScene
		if not item_scene.can_instantiate(): return
		item = item_scene.instantiate()
		add_child(item)
	else:
		if randf() > 0.4: return
		item = Globals.get_item_by_needs()
		if item == null: return
	item.global_position = global_position
	item.position += Vector3(0.5, -0.5, 0.0)
