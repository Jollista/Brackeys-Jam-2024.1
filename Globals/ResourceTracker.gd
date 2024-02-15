extends Node

# Resource points inspired by inventory system in CBR+PNK Augmented
var resource_point_max = 15
var resource_points = resource_point_max

# Stress mechanic stolen from Forged in the Dark
var stress_max = 10
var stress = stress_max

signal resource_changed

# set stress to a maximum of stress_max
func set_stress(new_stress:int):
	stress = new_stress
	stress = min(stress, stress_max)
	resource_changed.emit()

func get_stress():
	return stress



# set resource points to a maximum of resource_point_max
func set_stress_max(new_stress_max:int):
	stress_max = new_stress_max
	stress = min(stress, stress_max)
	resource_changed.emit()

func get_stress_max():
	return stress_max



# set resource points to a maximum of resource_point_max
func set_resource_points(new_resource_points:int):
	resource_points = new_resource_points
	resource_points = min(resource_points, resource_point_max)
	resource_changed.emit()

func get_resource_points():
	return resource_points



# set resource points to a maximum of resource_point_max
func set_resource_point_max(new_resource_point_max:int):
	resource_point_max = new_resource_point_max
	resource_points = min(resource_points, resource_point_max)
	resource_changed.emit()

func get_resource_point_max():
	return resource_point_max
