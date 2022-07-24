class_name Grid extends Node3D

var size: Vector2i
var cell_size: float
var _map: Array


func _init(grid_size: Vector2i, grid_cell_size: float = 1.0, default = null) -> void:
	assert(grid_size.x > 0); assert(grid_size.y > 0); assert(grid_cell_size > 0)
	
	size = grid_size
	cell_size = grid_cell_size
	
	_map.resize(grid_size.x * grid_size.y)
	
	if default != null:
		fill(default)

func fill(value) -> void:
	for i in range(_map.size()):
		_map[i] = value

func draw_debug_lines(y_offset: float = 0.02) -> void:
	var debug_draw = get_tree().root.get_node_or_null(NodePath("DebugDraw"))
	if debug_draw == null:
		return
	
	for x in range(size.x + 1):
		debug_draw.line(position + Vector3(x, y_offset, 0), position + Vector3(x, y_offset, size.y), Color.RED)
	for y in range(size.y + 1):
		debug_draw.line(position + Vector3(0, y_offset, y), position + Vector3(size.x, y_offset, y), Color.BLUE)
	


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
	
	var intersect = Plane.PLANE_XZ.intersects_ray(start, dir)
	if intersect == null:
		return Vector2i(-1, -1)
	
	var result := Vector2i(intersect.x / cell_size, intersect.z / cell_size)
	
	if result.x < 0 || result.y < 0 || result.x >= size.x || result.y >= size.y:
		return Vector2i(-1, -1)
	
	return result
