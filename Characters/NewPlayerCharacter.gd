extends Character

# true if is turn, else false
@export var my_turn = false

# navigation stuff
@onready var nav_agent:NavigationAgent3D = $"NavigationAgent3D"
var move_speed = 5

var moving = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# don't process anything else if navigation is finished
	if nav_agent.is_navigation_finished():
		# reset moving if not moving
		if velocity == Vector3.ZERO:
			moving = false
		return
	
	move_to_point(delta, move_speed)

func move_to_point(delta, speed):
	var target_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(target_pos)
	
	face_direction(target_pos)
	velocity = direction * speed
	move_and_slide()

func face_direction(direction):
	look_at(Vector3(direction.x, global_position.y, direction.z), Vector3.UP)

func _input(event):
	if my_turn and Input.is_action_just_pressed("left_mouse") and not moving:
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_length = 100
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * ray_length
		var space = get_world_3d().direct_space_state
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = from
		ray_query.to = to
		var result = space.intersect_ray(ray_query)
		print(result)
		
		if result.has("position"):
			moving = true # set moving to true to avoid multiple events fucking up distance
			
			# determine distance and try best to get there
			var distance = position.distance_to(result.position)
			
			if distance <= remaining_movement: # if within normal range
				print("distance is ", distance)
				nav_agent.target_position = result.position
				remaining_movement -= distance
			
			elif distance > remaining_movement: # else if outside, get to the closest point possible within range
				print("position ", position)
				print("result.position ", result.position)
				print("lerp result ", lerp(position, result.position, remaining_movement/distance))
				nav_agent.target_position = lerp(position, result.position, remaining_movement/distance)
				remaining_movement = 0
