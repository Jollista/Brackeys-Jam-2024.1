extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$DialogueCanvas.start_dialogue("res://Dialogue/JSONs/test.json")
