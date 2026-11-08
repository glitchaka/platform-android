extends Node2D
signal defeated
signal touched_player
const PIXEL = preload("res://Scripts/pixel_ui.gd")
var texture: Texture2D = preload("res://Resource/Enemies.png")
var alive := true
var target: Node2D
var patrol_min := 0.0
var patrol_max := 100.0
var speed := 24.0
var hp := 1
var max_hp := 1
var contact_damage := 1
var boss := false
var kind := "crawler"
var hurt_time := 0.0
var time := 0.0
var base_y := 0.0
var charge_direction := -1.0
var elite := false
var burn_damage := 0
var burn_time := 0.0
var burn_tick := 0.0

func configure(player: Node2D) -> void:
	target = player
	base_y = position.y

func tick(delta: float) -> void:
	if not alive:
		return
	time += delta
	hurt_time = maxf(0,hurt_time-delta)
	if burn_time > 0:
		burn_time -= delta
		burn_tick -= delta
		if burn_tick <= 0:
			burn_tick = 0.4
			hit(burn_damage)
			if not alive: return
	if boss:
		var phase := fmod(time,2.7)
		if phase < 0.8:
			speed = 0
			if target:
				charge_direction = signf(target.position.x-position.x)
		elif phase < 1.65:
			speed = charge_direction*(125 if elite or hp < max_hp/2 else 100)
		else:
			speed = charge_direction*18
	elif kind == "flyer":
		speed = 33 if speed>0 else -33
		position.y = base_y+sin(time*2.4)*10
	position.x += speed*delta
	if position.x <= patrol_min or position.x >= patrol_max:
		position.x = clampf(position.x,patrol_min,patrol_max)
		speed = -speed
		charge_direction = -charge_direction
	if target and absf(target.position.x-position.x)<(12 if boss else 8) and absf(target.position.y-position.y)<(14 if boss else 8):
		touched_player.emit()
	queue_redraw()

func hit(damage: int = 1) -> void:
	# Flashing is visual feedback; simultaneous shotgun pellets must all count.
	if not alive:
		return
	hp -= maxi(1,damage)
	hurt_time = 0.08
	if hp <= 0:
		alive = false
		visible = false
		defeated.emit()
	queue_redraw()

func ignite(damage: int) -> void:
	if burn_time <= 0: burn_tick = 0.4
	burn_time = 1.25
	burn_damage = maxi(burn_damage,damage)

func _draw() -> void:
	if not alive:
		return
	var frame := int(time*8)%(3 if boss else 4)
	var height := 16 if boss else 8
	var row := 120 if boss else 56 if kind == "flyer" else 40
	var source := Rect2(32+frame*8,row,8,height)
	var destination := Rect2(-4,4-height,8,height)
	if speed<0:
		destination.position.x += 8
		destination.size.x = -8
	draw_texture_rect_region(texture,destination,source,Color("ff9977") if hurt_time>0 or burn_time>0 else Color("bda5ff") if elite else Color.WHITE)
	if boss:
		for i in range(8):
			PIXEL.icon(self,"heart",Vector2(-32+i*8,-28),Color.WHITE if i<int(ceil(8.0*hp/max_hp)) else Color("575153"))
		if fmod(time,2.7)<0.8:
			PIXEL.text(self,Vector2(-4,-40),"!",Color("ed9a73"))
