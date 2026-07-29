extends CharacterBody2D

enum State {STATE_IDLE, STATE_RUN, STATE_JUMP, STATE_FALL, STATE_DUCK, STATE_WALL_SLIDE}

var state : State = State.STATE_IDLE

const ACCEL_RATE = 4.0
const FRICTION = 600.0
const AIR_SPEED = 1200.0
const SLIDE_SPEED = 50.0
const MAX_SPEED = 500.0
const JUMP_VELOCITY = -400.0

const WALL_SLIDE_SPEED = 80.0          # max fall speed while sliding down a wall
const WALL_JUMP_VELOCITY_Y = -300.0     # vertical kick off the wall
const WALL_JUMP_VELOCITY_X = 200.0      # horizontal push away from the wall
const WALL_JUMP_LOCK_TIME = 0.15        # seconds of ignoring input after a wall jump, so you actually leave the wall

var wall_jump_lock := 0.0

func _physics_process(delta: float) -> void:
	var idle = true

	if wall_jump_lock > 0:
		wall_jump_lock -= delta

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y > 0:
			changeState(State.STATE_FALL)
		idle = false

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("Left", "Right")

	# Wall slide check: airborne, touching a wall (not the floor), and moving toward it
	var on_wall := is_on_wall_only()
	var pressing_into_wall : bool = on_wall and sign(direction) == sign(get_wall_normal().x) * -1 and direction != 0

	if on_wall and not is_on_floor() and velocity.y > 0 and wall_jump_lock <= 0 and pressing_into_wall:
		# Slide slower than a normal fall
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		changeState(State.STATE_WALL_SLIDE)
		idle = false

	if wall_jump_lock <= 0:
		if direction:
			if is_on_floor():
				#velocity.x = move_toward(velocity.x, MAX_SPEED * direction, ACCELERATION * delta)
				velocity.x = lerp(velocity.x, MAX_SPEED * direction, 1.0 - exp(-ACCEL_RATE * delta))
				changeState(State.STATE_RUN)
			else:
				velocity.x = move_toward(velocity.x, MAX_SPEED * direction, AIR_SPEED * delta)
			idle = false

			# Flip sprite
			$Sprite2D.flip_h = direction < 0

		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			changeState(State.STATE_JUMP)
			idle = false
		elif on_wall:
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY_X
			velocity.y = WALL_JUMP_VELOCITY_Y
			wall_jump_lock = WALL_JUMP_LOCK_TIME
			changeState(State.STATE_JUMP)
			idle = false

			# Face away from the wall
			$Sprite2D.flip_h = wall_normal.x < 0

	if idle:
		changeState(State.STATE_IDLE)

	move_and_slide()

func changeState(newState : State) -> void:
	if state == newState:
		return

	state = newState
	if state == State.STATE_JUMP:
		$AnimationPlayer.play("jump")
	elif state == State.STATE_RUN:
		$AnimationPlayer.play("run")
	elif state == State.STATE_FALL:
		$AnimationPlayer.play("fall")
	elif state == State.STATE_DUCK:
		$AnimationPlayer.play("duck")
	elif state == State.STATE_WALL_SLIDE:
		$AnimationPlayer.play("wallslide")
	else:
		$AnimationPlayer.play("Idle")

func handleDeath() -> void:
	queue_free()
