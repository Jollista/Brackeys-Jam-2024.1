extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	print("combat start!")
	$DialogueCanvas.combat_start.emit("PCs")
