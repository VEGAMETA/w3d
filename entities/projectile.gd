class_name Projectile extends Area3D

@export var velocity : Vector3 = Vector3.ZERO
@export var damage : int = 3
@export var speed : float = 25.0
@export_flags_3d_physics var collision_mask_: int = 2


func _ready() -> void:
	body_entered.connect(hit)
	collision_mask = collision_mask_


func _physics_process(delta: float) -> void:
	global_position += velocity * speed * delta


func hit(body:Node3D) -> void:
	if body == null: return
	if body is Player and randf() < 0.25: return queue_free()
	if body.has_method("hit"):
		match (body.hit as Callable).get_argument_count():
			0: body.hit()
			1: body.hit(damage)
	queue_free()
