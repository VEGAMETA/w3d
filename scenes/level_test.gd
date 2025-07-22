extends Node3D

@onready var main_area: Area3D = %MainArea
@onready var main_music: AudioStreamPlayer = %MainMusic


func _ready() -> void:
	main_area.body_entered.connect(play_main_music)


func play_main_music(_body:Node3D) -> void:
	main_music.play()
