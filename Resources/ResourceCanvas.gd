extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	ResourceTracker.resource_changed.connect(update)
	update()

# update labels to accurately represent the current levels of each resource
func update():
	$Control/ResourceLabel.text = "Resources: " + str(ResourceTracker.get_resource_points()) + "/" + str(ResourceTracker.get_resource_point_max())
	$Control/StressLabel.text = "Stress: " + str(ResourceTracker.get_stress()) + "/" + str(ResourceTracker.get_stress_max())
