extends Node3D

@export var dialogue_filepath:String

# Called when the node enters the scene tree for the first time.
func _ready():
	$DialogueCanvas.start_dialogue(dialogue_filepath)
