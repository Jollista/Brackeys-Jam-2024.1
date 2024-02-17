extends Node3D

@export var theme:AudioStream

func _ready():
	GlobalMusicPlayer.play_song(theme)



func _on_button_pressed():
	get_tree().change_scene_to_file("res://Dialogue/Encounters/encounter1.tscn")
