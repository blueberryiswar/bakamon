extends CharacterBody2D

signal died

enum State {STATE_IDLE, STATE_RUN, STATE_JUMP, STATE_FALL, STATE_DUCK, STATE_WALL_SLIDE, STATE_PUSH, STATE_DOUBLEJUMP, STATE_STOMP}

var state : State = State.STATE_IDLE

@export var baseStateTexture : Texture2D
@export var devilStateTexture : Texture2D

const ACCEL_RATE = 4.0
const FRICTION = 600.0
const AIR_SPEED = 500.0
const SLIDE_SPEED = 50.0 # Maybe add to duck slide instead of friction
const MAX_SPEED = 300.0
const JUMP_VELOCITY = -400.0
const STOMP_VELOCITY = 500

const WALL_SLIDE_SPEED = 80.0          # max fall speed while sliding down a wall
const WALL_JUMP_VELOCITY_Y = -300.0     # vertical kick off the wall
const WALL_JUMP_VELOCITY_X = 200.0      # horizontal push away from the wall
const WALL_JUMP_LOCK_TIME = 0.15        # seconds of ignoring input after a wall jump, so you actually leave the wall
const PUSH_FORCE = 2000.0

var wall_jump_lock := 0.0
var needs_reset : bool = false
var devil_state : bool = false
var jump_lock : bool = false
var stomp_active : bool = false

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
	else:
		jump_lock = false

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("Left", "Right")
	
	if Input.is_action_pressed("Down") and is_on_floor() and !stomp_active:
		changeState(State.STATE_DUCK)
		idle = false
	elif state == State.STATE_DUCK and !stomp_active:
		changeState(State.STATE_RUN)
	elif Input.is_action_just_pressed("Down") and !stomp_active:
		doStomp()

	# Wall slide check: airborne, touching a wall (not the floor), and moving toward it
	var on_wall := is_on_wall_only()
	var pressing_into_wall : bool = on_wall and sign(direction) == sign(get_wall_normal().x) * -1 and direction != 0

	if on_wall and not is_on_floor() and velocity.y > 0 and wall_jump_lock <= 0 and pressing_into_wall:
		# Slide slower than a normal fall
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		changeState(State.STATE_WALL_SLIDE)
		idle = false

	if wall_jump_lock <= 0 and !stomp_active:
		if direction and state != State.STATE_DUCK:
			if is_on_floor():
				#velocity.x = move_toward(velocity.x, MAX_SPEED * direction, ACCELERATION * delta)
				velocity.x = lerp(velocity.x, MAX_SPEED * direction, 1.0 - exp(-ACCEL_RATE * delta))
				if state != State.STATE_PUSH:
					changeState(State.STATE_RUN)
			else:
				velocity.x = move_toward(velocity.x, MAX_SPEED * direction, AIR_SPEED * delta)
			idle = false

			# Flip sprite
			$Sprite2D.flip_h = direction < 0

		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			
	if stomp_active:
		if is_on_floor():
			resetStomp()
		else:
			velocity = Vector2(0.0, STOMP_VELOCITY)
			
		idle = false

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and !stomp_active:
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
			jump_lock = false
			idle = false
			# Face away from the wall
			$Sprite2D.flip_h = wall_normal.x < 0
		elif devil_state and !jump_lock:
			velocity.y = JUMP_VELOCITY
			changeState(State.STATE_DOUBLEJUMP)
			jump_lock = true

	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D and collider.is_in_group("Movable"):
			var push_direction = -collision.get_normal()
			collider.apply_central_force(push_direction * PUSH_FORCE)
			if push_direction.y == 0:
				changeState(State.STATE_PUSH)
				idle = false
	
	if idle:
		changeState(State.STATE_IDLE)

func changeState(newState : State) -> void:
	if state == newState:
		return
		
	if needs_reset:
		resetState()

	state = newState
	if state == State.STATE_JUMP:
		$AnimationPlayer.play("jump")
	elif state == State.STATE_RUN:
		$AnimationPlayer.play("run")
	elif state == State.STATE_FALL:
		$AnimationPlayer.play("fall")
	elif state == State.STATE_DUCK:
		handleDucking()
	elif state == State.STATE_WALL_SLIDE:
		$AnimationPlayer.play("wallslide")
	elif state == State.STATE_PUSH:
		$AnimationPlayer.play("push")
	elif state == State.STATE_DOUBLEJUMP:
		$AnimationPlayer.play("doublejump")
	elif state == State.STATE_STOMP:
		$AnimationPlayer.play("stomp")
	else:
		$AnimationPlayer.play("Idle")
		
func handleDucking() -> void:
	$AnimationPlayer.play("duck")
	$Ducking.set_deferred("disabled", false)
	$Standing.set_deferred("disabled", true)
	needs_reset = true
	
func resetState() -> void:
	$Ducking.set_deferred("disabled", true)
	$Standing.set_deferred("disabled", false)
	$Sprite2D.set_deferred("rotation", 0.0)
	$Standing.set_deferred("rotation", 0.0)
	needs_reset = false
	
func doStomp() -> void:
	if stomp_active:
		return
	stomp_active = true
	var tween = create_tween()
	tween.tween_property($Sprite2D, "rotation", PI, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($Sprite2D, "position", Vector2(0.0,5.0), 0.1)
	changeState(State.STATE_STOMP)
	
func resetStomp() -> void:
	if !stomp_active:
		return
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(1.2,0.8), 0.05)
	tween.parallel().tween_property($Sprite2D, "position", Vector2(0,10.0),0.05)
	tween.tween_property($Sprite2D, "scale", Vector2(1.0,1.0), 0.05)
	tween.parallel().tween_property($Sprite2D, "position", Vector2(0,0.0),0.05)
	tween.tween_property($Sprite2D, "rotation", 0.0, 0.05)
	tween.tween_callback(func(): stomp_active = false)

func eatPowerup(type) -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(1.2,1.2), 0.1)
	if type == 0:
		$Sprite2D.texture = devilStateTexture
		devil_state = true
	tween.tween_property($Sprite2D, "scale", Vector2(1.0,1.0), 0.1)

func handleDeath() -> void:
	died.emit()
	queue_free()


func _on_stomp_body_entered(body: Node2D) -> void:
	if !stomp_active:
		return
	if body.has_method("handleStomp"):
		body.handleStomp()
