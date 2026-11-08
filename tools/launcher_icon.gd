extends Node2D
const PIXEL = preload("res://Scripts/pixel_ui.gd")
const PLAYER = preload("res://Resource/Player.png")
var mode := "main"

func _draw() -> void:
	if mode == "background":
		PIXEL.strip(self,Rect2(0,0,432,432),Color("363d3a"))
	elif mode == "foreground":
		draw_texture_rect_region(PLAYER,Rect2(120,120,192,192),Rect2(0,64,8,8))
	else:
		PIXEL.panel(self,Rect2(0,0,192,192),Color("a9b89f"))
		draw_texture_rect_region(PLAYER,Rect2(48,48,96,96),Rect2(0,64,8,8))
