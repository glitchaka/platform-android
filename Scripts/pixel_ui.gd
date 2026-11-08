@tool
extends RefCounted

# All interface graphics and glyphs are native regions of the supplied UI atlas.
const TEXTURE = preload("res://Resource/UI.png")
const INK = Color("302f29")
const ICONS = {
	"heart": Rect2(0,40,8,8), "coin": Rect2(64,40,8,8),
	"map": Rect2(16,40,8,8), "player": Rect2(32,40,8,8),
	"enemy": Rect2(40,40,8,8), "key": Rect2(56,40,8,8),
	"chest": Rect2(64,40,8,8), "save": Rect2(136,40,8,8),
	"goal": Rect2(152,40,8,8), "jump": Rect2(120,40,8,8),
	"dash": Rect2(120,40,8,8), "power": Rect2(112,40,8,8),
	"rapid": Rect2(120,40,8,8)
}

static func icon(canvas: CanvasItem, name: String, pos: Vector2, tint := Color.WHITE) -> void:
	if name == "jump":
		icon_scaled(canvas,name,pos+Vector2(4,4),8,tint)
		return
	canvas.draw_texture_rect_region(TEXTURE,Rect2(pos,Vector2(8,8)),ICONS.get(name,ICONS.goal),tint)

static func icon_scaled(canvas: CanvasItem, name: String, center: Vector2, size: float, tint := Color.WHITE) -> void:
	if name == "jump":
		# The atlas has a horizontal arrow; turn that existing sprite upwards for jump.
		canvas.draw_set_transform(center.round(),-PI/2)
		canvas.draw_texture_rect_region(TEXTURE,Rect2(-Vector2.ONE*size/2,Vector2.ONE*size),ICONS.jump,tint)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	canvas.draw_texture_rect_region(TEXTURE,Rect2((center-Vector2.ONE*size/2).round(),Vector2.ONE*size),ICONS.get(name,ICONS.goal),tint)

static func shadow_text(canvas: CanvasItem, pos: Vector2, value: String, tint := Color.WHITE) -> void:
	text(canvas,pos+Vector2(1,1),value,Color(0.04,0.06,0.05,tint.a*0.85))
	text(canvas,pos,value,tint)

static func ring(canvas: CanvasItem, center: Vector2, radius: int, tint: Color, fill_alpha := 0.04) -> void:
	# Pixel-stepped rings sample UI.png, just like the atlas routes. No native UI theme.
	for y in range(-radius,radius+1):
		var half := int(sqrt(maxf(0,radius*radius-y*y)))
		var inner := int(sqrt(maxf(0,(radius-1)*(radius-1)-y*y))) if absi(y)<radius-1 else -1
		if fill_alpha > 0 and inner > 0:
			strip(canvas,Rect2(center+Vector2(-inner,y),Vector2(inner*2+1,1)),Color(tint.r,tint.g,tint.b,fill_alpha))
		var edge := half-inner
		strip(canvas,Rect2(center+Vector2(-half,y),Vector2(edge,1)),tint)
		strip(canvas,Rect2(center+Vector2(inner+1,y),Vector2(edge,1)),tint)

static func panel(canvas: CanvasItem, rect: Rect2, tint := Color.WHITE) -> void:
	var sizes_x := [3.0,rect.size.x-6.0,3.0]
	var sizes_y := [3.0,rect.size.y-6.0,3.0]
	var cuts := [0.0,3.0,21.0]
	var lengths := [3.0,18.0,3.0]
	var y := rect.position.y
	for row in range(3):
		var x := rect.position.x
		for col in range(3):
			canvas.draw_texture_rect_region(TEXTURE,Rect2(x,y,sizes_x[col],sizes_y[row]),Rect2(64+cuts[col],cuts[row],lengths[col],lengths[row]),tint)
			x += sizes_x[col]
		y += sizes_y[row]

static func glyph(character: String) -> Rect2:
	var code := character.unicode_at(0)
	if code >= 65 and code <= 90:
		var index := code-65
		return Rect2((index%13)*8,88+int(index/13)*8,8,8)
	if code >= 48 and code <= 57:
		return Rect2((code-48)*8,64,8,8)
	var punctuation := {".":0,"!":1,"?":2,",":3,"'":4,":":5,";":6,"+":7,"-":8}
	if punctuation.has(character):
		return Rect2(punctuation[character]*8,80,8,8)
	return Rect2()

static func text(canvas: CanvasItem, pos: Vector2, value: String, tint := Color.WHITE) -> void:
	var normalized := value.to_upper().replace("Á","A").replace("É","E").replace("Í","I").replace("Ó","O").replace("Ú","U").replace("Ñ","N")
	var cursor := pos.round()
	for character in normalized:
		if character == "\n":
			cursor.x = pos.x
			cursor.y += 10
			continue
		var source := glyph(character)
		if source.size != Vector2.ZERO:
			canvas.draw_texture_rect_region(TEXTURE,Rect2(cursor,Vector2(8,8)),source,tint)
		cursor.x += 8

static func wrap(value: String, columns := 37) -> String:
	var lines := PackedStringArray()
	for line in value.split("\n"): lines.append(wrap_line(line,columns))
	return "\n".join(lines)

static func wrap_line(value: String, columns: int) -> String:
	var result := ""
	var count := 0
	for word in value.split(" "):
		if count > 0 and count+1+word.length() > columns:
			result += "\n"
			count = 0
		if count > 0:
			result += " "
			count += 1
		result += word
		count += word.length()
	return result

static func strip(canvas: CanvasItem, rect: Rect2, tint: Color) -> void:
	canvas.draw_texture_rect_region(TEXTURE,rect,Rect2(70,6,1,1),tint)

static func route(canvas: CanvasItem, a: Vector2, b: Vector2, tint: Color) -> void:
	var elbow := Vector2(b.x,a.y)
	strip(canvas,Rect2(Vector2(minf(a.x,elbow.x),a.y),Vector2(maxf(absf(elbow.x-a.x),1),1)),tint)
	strip(canvas,Rect2(Vector2(b.x,minf(elbow.y,b.y)),Vector2(1,maxf(absf(b.y-elbow.y),1))),tint)
