extends Node2D

signal collected
const COLLECTABLES_TEXTURE = preload("res://Resource/Collectables.png")
var collected_already := false

func tick(player: Node2D) -> void:
	if not collected_already and position.distance_to(player.position) < 10.0:
		collected_already = true
		collected.emit()
	queue_redraw()

func _draw() -> void:
	if collected_already:
		return
	var pulse := 5.0 + sin(Time.get_ticks_msec() / 180.0) * 2.0
	draw_circle(Vector2.ZERO, pulse + 6.0, Color(0.93, 0.72, 0.33, 0.12))
	draw_circle(Vector2.ZERO, pulse, Color("f1d06b"))
	draw_circle(Vector2.ZERO, 3.0, Color("fff2bf"))
	draw_texture_rect_region(COLLECTABLES_TEXTURE, Rect2(-4, -4, 8, 8), Rect2(0, 0, 8, 8))
