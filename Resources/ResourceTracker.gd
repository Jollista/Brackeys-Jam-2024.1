extends CanvasLayer

# Resource points inspired by inventory system in CBR+PNK Augmented
@export var resource_point_max = 15
@onready var resource_points = resource_point_max

# Stress mechanic stolen from Forged in the Dark
@export var stress_max = 10
@onready var stress = stress_max

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
