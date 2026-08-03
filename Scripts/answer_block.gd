extends StaticBody2D

enum BlockType {POWERUP, BREAKABLE, DISAPEAR, STANDARD}

@export var powerupScene: PackedScene
@export var blockType : BlockType
var used : bool = false
var originalPosition : Vector2

func _ready() -> void:
	originalPosition = $Sprite2D.position

func hit_from_below() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "position", originalPosition + Vector2(0,-8), 0.1)
	tween.tween_property($Sprite2D, "position", originalPosition, 0.1)
	#tween.parallel().tween_property($CollisionShape2D, "position", Vector2(position.x, position.y + 4), 0.2)
	handleDefaultAction()

func handleStomp() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "position", originalPosition + Vector2(0,8), 0.1)
	tween.tween_property($Sprite2D, "position", originalPosition, 0.1)
	handleDefaultAction()

func handleDefaultAction() -> void:
	if blockType == BlockType.POWERUP:
		spawnPowerup()
	elif blockType == BlockType.BREAKABLE:
		breakBlock()

func _on_bottom_detector_body_entered(body: Node2D) -> void:
	# Only trigger if the body is actually bellow block
	if body is CharacterBody2D and body.position.y > position.y:
		hit_from_below()

func spawnPowerup() -> void:
	if used:
		return
	used = true
	$Sprite2D.frame = 1
	var powerup = powerupScene.instantiate()
	get_parent().add_child.call_deferred(powerup)
	powerup.global_position = global_position + Vector2(12, -18)

func breakBlock() -> void:
	queue_free()
	
func disapear() -> void:
	pass
