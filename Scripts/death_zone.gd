extends Area2D

func _on_body_entered(body):
	print("Entered by: ", body.name)
	if body.has_method("handleDeath"):
		body.handleDeath()
	else:
		body.queue_free()
