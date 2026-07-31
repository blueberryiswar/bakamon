extends Node2D

@export var targetObject : PackedScene
@export var respawnOnDeath : bool = false
@export var respawnTimer : float = 0.5
@export var continuousSpawn : bool = false
@export var spawnDelay : float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawnObject()
		

func spawnObject() -> void:
	var object = targetObject.instantiate()
	get_parent().add_child.call_deferred(object)
	object.global_position = global_position
	if respawnOnDeath and object.has_signal("died"):
		object.died.connect(_on_object_died)
	if(continuousSpawn and spawnDelay > 0):
		await get_tree().create_timer(spawnDelay).timeout
		spawnObject()

func _on_object_died() -> void:
	if (respawnTimer > 0):
		await get_tree().create_timer(respawnTimer).timeout
	spawnObject()
