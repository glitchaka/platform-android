@tool
extends RefCounted

# Native 8px terrain regions. The supplied atlases and their alpha stay intact.
const TEXTURES = {
	"Musgo": preload("res://Resource/tilesets/moss_full.png"),
	"Roca": preload("res://Resource/tilesets/rocks_full.png"),
	"Ladrillo": preload("res://Resource/tilesets/bricks_full.png"),
	"Brasa": preload("res://Resource/tilesets/orange_full.png"),
	"Bosque": preload("res://Resource/tilesets/Tiles-and-Enemies.png"),
	"Escarcha": preload("res://Resource/tilesets/Tiles-and-Enemies.png"),
	"Caverna": preload("res://Resource/tilesets/tileset.png")
}
const PROPS = preload("res://Resource/tilesets/props_full.png")
const POT = preload("res://Resource/tilesets/pot.png")
const BACKGROUNDS = {"Musgo":"142b29", "Roca":"242332", "Ladrillo":"20212e", "Brasa":"301d2b", "Bosque":"15251f", "Escarcha":"192633", "Caverna":"171e30"}

static func piece(canvas: CanvasItem, texture: Texture2D, source: Rect2, pos: Vector2, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect_region(texture,Rect2(pos,source.size),source,tint)

static func platform(canvas: CanvasItem, rect: Rect2, style: String) -> void:
	var texture: Texture2D = TEXTURES[style]
	var forest := style in ["Bosque","Escarcha"]
	var offset := 104 if style == "Escarcha" else 0
	for y in range(0,int(rect.size.y),8):
		for x in range(0,int(rect.size.x),8):
			var right := x+8>=rect.size.x
			var bottom := y+8>=rect.size.y
			var source := Vector2(0 if x==0 else 24 if right else 8+(x/8%2)*8,0 if y==0 else 24 if bottom else 8+(y/8%2)*8)
			if forest:
				source = Vector2(offset+(0 if x==0 else 40 if right else 8+(x/8%4)*8),16 if y==0 else 24 if bottom else 64+(y/8%3)*8)
				if y>0 and not bottom:
					# Only columns 0..2 are soil; column 4 already contains moon props.
					source.x = offset+(x/8%3)*8
			elif style == "Caverna":
				source = Vector2(0 if x==0 else 16 if right else 8,48 if y==0 else 64 if bottom else 56)
			var size := Vector2(minf(8,rect.size.x-x),minf(8,rect.size.y-y))
			canvas.draw_texture_rect_region(texture,Rect2(rect.position+Vector2(x,y),size),Rect2(source,size))

static func decoration(canvas: CanvasItem, root: Vector2, style: String, variant: int) -> void:
	if style in ["Bosque","Escarcha"]:
		var offset := 104 if style == "Escarcha" else 0
		piece(canvas,TEXTURES[style],Rect2(offset+64+(variant%3)*8,96,8,8),root-Vector2(4,8))
	elif variant%3 == 0:
		piece(canvas,POT,Rect2(0,0,16,16),root-Vector2(8,16),Color("89958e"))
	else:
		piece(canvas,PROPS,Rect2((variant%3)*8,0,8,8),root-Vector2(4,8))

static func background(canvas: CanvasItem, size: Vector2, floor_y: float, style: String) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(BACKGROUNDS.get(style,"1d2122")))
	# Recessed masonry suggests the room's height without obscuring actors.
	for x in range(24,int(size.x)-32,64):
		for y in range(40,int(floor_y)-24,32):
			var texture: Texture2D = TEXTURES[style]
			var source := Rect2(64,8,16,16)
			if style in ["Bosque","Escarcha"]:
				source = Rect2(104 if style=="Escarcha" else 0,64,16,16)
			elif style=="Caverna":
				source = Rect2(48,0,16,16)
			if (x/64+y/32)%3 != 0:
				piece(canvas,texture,source,Vector2(x,y),Color(0.55,0.65,0.68,0.16))
