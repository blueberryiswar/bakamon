extends RigidBody2D

@export var powerUpType = 0
const SPEED : float = 100.0
var direction : float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.frame = powerUpType
	contact_monitor = true
	max_contacts_reported = 4
	lock_rotation = true

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# 3. Check if the powerup collided with anything this frame
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			var normal = state.get_contact_local_normal(i)
			
			# 4. If hitting a vertical wall (left or right side hit)
			if abs(normal.x) > 0.7:
				# Invert the direction based on the wall's orientation
				direction = sign(normal.x)
				break

	# 5. Overwrite the velocity safely within the physics state
	state.linear_velocity.x = direction * SPEED
