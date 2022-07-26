extends Node3D


func line(start: Vector3, end: Vector3, color: Color, time: float = -1.0) -> int:
	var material := ORMMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	add_child(mesh_instance)
	if time != -1:
		var timer := get_tree().create_timer(time)
		timer.timeout.connect(_on_debug_expired.bind(mesh_instance))
		mesh_instance.set_meta("timer", timer)
	
	return mesh_instance.get_instance_id()


func remove(id: int) -> void:
	var node: Node = instance_from_id(id)
	if node.has_meta("timer"):
		var timer: SceneTreeTimer = node.get_meta("timer")
		timer.timeout.disconnect(_on_debug_expired)
	node.free()


func _on_debug_expired(node: Node) -> void:
	if node != null:
		node.free()
