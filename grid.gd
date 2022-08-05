class_name Grid extends Node3D

@export
var size: Vector2i
@export
var cell_size: float

var _map_data: Array

var _cache_map_path: Array[PackedInt64Array]
var _cache_map_cost: PackedFloat64Array
var _map_obstacle # Callable or null; func(from: Vector2i, to: Vector2i, offset: Vector2i) -> ObstacleProperty


func _init(grid_size: Vector2i, grid_cell_size: float = 1.0, default = null, pos: Vector3 = Vector3.ZERO) -> void:
	assert(grid_size.x > 0); assert(grid_size.y > 0); assert(grid_cell_size > 0)
	
	size = grid_size
	cell_size = grid_cell_size
	position = pos
	
	_map_data.resize(grid_size.x * grid_size.y)
	
	if default != null:
		fill(default)


func fill(value) -> void:
	var call_new := false
	if typeof(value) == TYPE_OBJECT && "new" in value:
		call_new = true
	for i in range(_map_data.size()):
		if call_new:
			_map_data[i] = value.new()
		else:
			_map_data[i] = value


func is_in_bound(vector: Vector2i) -> bool:
	return vector.x >= 0 && vector.y >= 0 && vector.x < size.x && vector.y < size.y


func get_cellv(pos: Vector2i):
	assert(is_in_bound(pos))
	return _map_data[pos.y * size.x + pos.x]


func get_cell(x: int, y: int):
	return get_cellv(Vector2i(x, y))


func set_cellv(pos: Vector2i, value) -> void:
	assert(is_in_bound(pos))
	_map_data[pos.y * size.x + pos.x] = value


func set_cell(x: int, y: int, value) -> void:
	set_cellv(Vector2i(x, y), value)


func get_local_position_fromf(viewport_position: Vector2, camera: Camera3D = get_viewport().get_camera_3d()) -> Vector2:
	assert(camera != null)
	
	var start := camera.project_ray_origin(viewport_position)
	var dir := camera.project_ray_normal(viewport_position)
	
	var intersect = Plane(0, 1, 0, position.y).intersects_ray(start, dir)
	if intersect == null:
		return Vector2(-1.0, -1.0)
	
	var result: Vector3 = (intersect - position) / cell_size
	if result.x < 0 || result.z < 0 || result.x >= size.x || result.z >= size.y:
		return Vector2(-1.0, -1.0)
	
	return Vector2(result.x, result.z)


func get_local_position_from(viewport_position: Vector2, camera: Camera3D = get_viewport().get_camera_3d()) -> Vector2i:
	return Vector2i(get_local_position_fromf(viewport_position, camera))


func get_global_position_centerv(pos: Vector2i) -> Vector3:
	assert(is_in_bound(pos))
	return Vector3(cell_size * (pos.x + 1 / 2.0) , 0, cell_size * (pos.y + 1 / 2.0)) + position


func get_global_position_center(x: int, y: int) -> Vector3:
	return get_global_position_centerv(Vector2i(x, y))


func draw_debug_lines(y_offset: float = 0.02) -> void:
	var debug_draw = get_tree().root.get_node_or_null(NodePath("DebugDraw"))
	if debug_draw == null:
		return
	
	for x in range(size.x + 1):
		debug_draw.line(position + Vector3(x, y_offset, 0), position + Vector3(x, y_offset, size.y), Color.RED)
	for y in range(size.y + 1):
		debug_draw.line(position + Vector3(0, y_offset, y), position + Vector3(size.x, y_offset, y), Color.BLUE)


func _vector_to_id(vector: Vector2i) -> int:
	if !is_in_bound(vector):
		return -1
	return vector.y * size.x + vector.x


func _xy_to_id(x: int, y: int) -> int:
	return _vector_to_id(Vector2i(x, y))


func _id_to_vector(id: int) -> Vector2i:
	if id < 0 || id >= size.x * size.y:
		return Vector2i(-1, -1)
	@warning_ignore(integer_division)
	return Vector2i(id % size.x, id / size.x)


class ObstacleProperty:
	var is_calculate: bool = true
	var to_coord := Vector2i(-1, -1)
	var cost: float = 1.0

# TODO Pass checkable offset from tile
func initialize_path_finding(obstacle = null) -> void:
	assert(typeof(obstacle) == TYPE_NIL || typeof(obstacle) == TYPE_CALLABLE)
	_cache_map_path.resize(size.x * size.y)
	_cache_map_cost.resize(size.x * size.y)
	_map_obstacle = obstacle


func generate_path_from(pos: Vector2i, max_cost: float):
	_cache_map_path.fill(PackedInt64Array())
	_cache_map_cost.fill(-1.0)
	
	var pos_id := _vector_to_id(pos)
	_cache_map_path[pos_id] = PackedInt64Array([pos_id])
	_cache_map_cost[pos_id] = 0
	
	var stack: Array[int] = [pos_id]
	while !stack.is_empty():
		var pop_id: int = stack.pop_back()
		var pop_pos := _id_to_vector(pop_id)
		
		var offset_list: Array[Vector2i] = [
				Vector2i.UP, Vector2i.UP + Vector2i.RIGHT,
				Vector2i.RIGHT, Vector2i.DOWN + Vector2i.RIGHT,
				Vector2i.DOWN, Vector2i.DOWN + Vector2i.LEFT,
				Vector2i.LEFT, Vector2i.UP + Vector2i.LEFT
			]
		
		for offset in offset_list:
			if _map_obstacle is Callable:
				var to_pos := pop_pos + offset
				if !is_in_bound(to_pos):
					continue
				
				var property: ObstacleProperty = _map_obstacle.call(pop_pos, to_pos, offset)
				if !property.is_calculate:
					continue
				
				if property.to_coord == Vector2i(-1, -1):
					property.to_coord = to_pos
				
				if _path_check_cost(pop_id, _vector_to_id(property.to_coord), property.cost, max_cost):
					stack.append(_vector_to_id(property.to_coord))
			elif _map_obstacle == null:
				# TODO
				pass


func _path_check_cost(node_id: int, next_node_id: int, cost: float, max_cost: float) -> bool:
	if next_node_id != -1 && _cache_map_cost[node_id] + cost <= max_cost:
		if _cache_map_cost[next_node_id] == -1 || _cache_map_cost[next_node_id] > _cache_map_cost[node_id] + cost:
			_cache_map_cost[next_node_id] = _cache_map_cost[node_id] + cost
			_cache_map_path[next_node_id] = _cache_map_path[node_id].duplicate()
			_cache_map_path[next_node_id].append(next_node_id)
			return true
	return false


func get_path_points_to(pos: Vector2i) -> PackedVector2Array:
	assert(is_in_bound(pos))
	var result := PackedVector2Array()
	var id := _vector_to_id(pos)
	result.resize(_cache_map_path[id].size())
	for i in range(_cache_map_path[id].size()):
		result[i] = Vector2(_id_to_vector(_cache_map_path[id][i]))
	return result


func get_path_cost_to(pos: Vector2i) -> float:
	assert(is_in_bound(pos))
	return _cache_map_cost[_vector_to_id(pos)]


func dda_raycast(from, to, obstacle = null):
	if from is Vector2i: # Center of cell
		from = Vector2(from) + Vector2(0.5, 0.5)
	elif !from is Vector2:
		@warning_ignore(assert_always_false)
		assert(false)
	
	if to is Vector2i: # Center of cell
		to = Vector2(to) + Vector2(0.5, 0.5)
	elif !to is Vector2:
		@warning_ignore(assert_always_false)
		assert(false)
	
	# Note float can divide by 0, result +-inf
	
	var distance_x: float = abs(to.x - from.x)
	var distance_y: float = abs(to.y - from.y)
	
	var dydx: float = (from.y - to.y) / (from.x - to.x)
	var dxdy: float = (from.x - to.x) / (from.y - to.y)
	
	var scale_x: float = sqrt(1 + pow(dydx, 2))
	var scale_y: float = sqrt(1 + pow(dxdy, 2))
	
	var length_x: float = scale_x
	var length_y: float = scale_y
	
	var current := Vector2i(from)
	
	var step_x: int
	var step_y: int
	
	if from.x > to.x:
		step_x = -1
		length_x = (from.x - float(current.x)) * scale_x
	else:
		step_x = 1
		length_x = (float(current.x + 1) - from.x) * scale_x
	
	if from.y > to.y:
		step_y = -1
		length_y = (from.y - float(current.y)) * scale_y
	else:
		step_y = 1
		length_y = (float(current.y + 1) - from.y) * scale_y
		
	var travel_list: Array[Vector2i] = [current]
	
	while true:
		var is_x_small: bool = false
		var length_small: float
		if length_x < length_y:
			current.x += step_x
			length_small = length_x
			length_x += scale_x
			is_x_small = true
			
		else:
			current.y += step_y
			length_small = length_y
			length_y += scale_y
		
		if (is_x_small && length_small > distance_x) || (!is_x_small && length_small > distance_y) || !is_in_bound(current):
			return [null, Vector2i(-1, -1), travel_list]
		
		if obstacle is Callable:
			if obstacle.call(current):
				return [from + ((to - from).normalized() * length_small), current, travel_list]
		else:
			# TODO null
			pass
			
		travel_list.append(current)
