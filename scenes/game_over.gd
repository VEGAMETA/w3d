extends Control

var level : String = "uid://byuguouwmac2s"

@onready var audio_game_over = %GameOver

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Attack"): get_tree().change_scene_to_file(level)

func _ready() -> void:
	get_tree().create_timer(0.82).timeout.connect(game_over)

func game_over() -> void:
	audio_game_over.play()
	
