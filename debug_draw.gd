extends Node3D


func line(start: Vector3, end: Vector3, color: Color) -> void:
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
