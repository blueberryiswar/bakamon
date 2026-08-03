extends RigidBody2D

@export var powerUpType = 0
const SPEED : float = 100.0
var direction : float = 1.0

func _ready() -> void:
	$Sprite2D.frame = powerUpType
	contact_monitor = true
	max_contacts_reported = 4
	lock_rotation = true

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			var normal = state.get_contact_local_normal(i)
			
			# If hitting a vertical wall (left or right side hit)
			if abs(normal.x) > 0.7:
				# Invert the direction based on the wall's orientation
				direction = sign(normal.x)
				break

	# Overwrite the velocity safely within the physics state
	state.linear_velocity.x = direction * SPEED


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("Player"):
		var tween = create_tween()
		tween.tween_property($Sprite2D, "scale", Vector2(0.5,0.5), 0.2)
		body.eatPowerup(powerUpType)
		queue_free()
