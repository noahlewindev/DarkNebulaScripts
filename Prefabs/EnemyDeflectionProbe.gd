extends Area3D


func _on_area_entered(area: Area3D) -> void:
	if !area.get_collision_mask_value(2):
		area.Flip()
