extends StaticBody2D

@export var powerupScene: PackedScene
var used : bool = false


func hit_from_below() -> void:
	var originalPosition : Vector2 = $Sprite2D.position
	var tween = create_tween()
	tween.tween_property($Sprite2D, "position", originalPosition + Vector2(0,-8), 0.1)
	tween.tween_property($Sprite2D, "position", originalPosition, 0.1)
	#tween.parallel().tween_property($CollisionShape2D, "position", Vector2(position.x, position.y + 4), 0.2)
	if used:
		return
	used = true
	$Sprite2D.frame = 1
	var powerup = powerupScene.instantiate()
	get_parent().add_child.call_deferred(powerup)
	powerup.global_position = global_position + Vector2(12, -18)


func _on_bottom_detector_body_entered(body: Node2D) -> void:
	# Only trigger if the body is actually bellow block
	if body is CharacterBody2D and body.position.y > position.y:
		hit_from_below()
