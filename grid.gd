class_name Grid extends Node3D

var size: Vector2i
var cell_size: float
var _map: Array
var astar: AStar2D = null


func _init(grid_size: Vector2i, grid_cell_size: float = 1.0, default = null, pos: Vector3 = Vector3.ZERO) -> void:
	assert(grid_size.x > 0); assert(grid_size.y > 0); assert(grid_cell_size > 0)
	
	size = grid_size
	cell_size = grid_cell_size
	position = pos
	
	_map.resize(grid_size.x * grid_size.y)
	
	if default != null:
		fill(default)


func fill(value) -> void:
	var call_new := false
	if typeof(value) == TYPE_OBJECT && "new" in value:
		call_new = true
	for i in range(_map.size()):
		if call_new:
			_map[i] = value.new()
		else:
			_map[i] = value


func construct_astar(diagonal: bool = true) -> void:
	astar = AStar2D.new()
	astar.reserve_space(size.x * size.y)
	for x in range(size.x):
		for y in range(size.y):
			astar.add_point(_xy_to_id(x, y), Vector2i(x, y))
	
	for x in range(size.x):
		for y in range(size.y):
			if x + 1 < size.x:
				astar.connect_points(_xy_to_id(x, y), _xy_to_id(x + 1, y))
			if y + 1 < size.y:
				astar.connect_points(_xy_to_id(x, y), _xy_to_id(x, y + 1))
			if diagonal && x + 1 < size.x && y + 1 < size.y:
				astar.connect_points(_xy_to_id(x, y), _xy_to_id(x + 1, y + 1))


func astar_get_path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	var arr := astar.get_id_path(_vector_to_id(from), _vector_to_id(to))
	var arr2 := PackedVector2Array()
	arr2.resize(arr.size())
	for i in range(arr.size()):
		arr2[i] = Vector2(_id_to_vector(arr[i]))
	return arr2

func get_cellv(pos: Vector2i):
	assert(pos.x >= 0); assert(pos.y >= 0); assert(pos.x < size.x); assert(pos.y < size.y)
	return _map[pos.y * size.x + pos.x]


func get_cell(x: int, y: int):
	return get_cellv(Vector2i(x, y))


func set_cellv(pos: Vector2i, value) -> void:
	assert(pos.x >= 0); assert(pos.y >= 0); assert(pos.x < size.x); assert(pos.y < size.y)
	_map[pos.y * size.x + pos.x] = value


func set_cell(x: int, y: int, value) -> void:
	set_cellv(Vector2i(x, y), value)


func get_local_position_from(viewport_position: Vector2, camera: Camera3D = get_viewport().get_camera_3d()) -> Vector2i:
	assert(camera != null)
	
	var start := camera.project_ray_origin(viewport_position)
	var dir := camera.project_ray_normal(viewport_position)
	
	var intersect = Plane(0, 1, 0, position.y).intersects_ray(start, dir)
	if intersect == null:
		return Vector2i(-1, -1)
	
	var result: Vector3 = (intersect - position) / cell_size
	if result.x < 0 || result.z < 0 || result.x >= size.x || result.z >= size.y:
		return Vector2i(-1, -1)
	
	return Vector2i(int(result.x), int(result.z))


func get_global_position_centerv(pos: Vector2i) -> Vector3:
	assert(pos.x >= 0); assert(pos.y >= 0); assert(pos.x < size.x); assert(pos.y < size.y)
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
	if vector.x < 0 || vector.y < 0 || vector.x >= size.x || vector.y >= size.y:
		return -1
	return vector.y * size.x + vector.x


func _xy_to_id(x: int, y: int) -> int:
	return _vector_to_id(Vector2i(x, y))


func _id_to_vector(id: int) -> Vector2i:
	if id < 0 || id >= size.x * size.y:
		return Vector2i(-1, -1)
	@warning_ignore(integer_division)
	return Vector2i(id % size.x, id / size.x)
