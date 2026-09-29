extends "res://particles/pooled_particles.gd"

func restart() -> void :
	.restart()

func _on_FinishedTimer_timeout() -> void :
	queue_free()
