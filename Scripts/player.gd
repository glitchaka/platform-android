extends Node2D

signal health_changed(value: int)
signal attack_hit
signal sound_requested(id: String)
signal damage_received
const SPEED := 96.0
const JUMP_SPEED := -220.0
const GRAVITY := 620.0
const PLAYER_TEXTURE = preload("res://Resource/Player.png")
const ATLAS = preload("res://Scripts/sprite_atlas.gd")
var velocity := Vector2.ZERO
var facing := 1.0
var grounded := false
var health := 3
var max_health := 3
var attack_timer := 0.0
var muzzle_timer := 0.0
var weapon_damage := 1
var armor := 0
var rapid_fire := false
var fire_interval := 0.3
var speed_bonus := 1.0
var invulnerable_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var jumps := 0
var double_jump := false
var dash := false
var bounds := Vector2(320,176)
var platforms: Array[Rect2] = []
var sprite: AnimatedSprite2D
var shield := false
var trail_enabled := false
var trail: Array[Dictionary] = []
var trail_timer := 0.0

func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_animation(frames,"idle",64,4,4)
	add_animation(frames,"run",16,8,10)
	add_animation(frames,"jump",88,1,1)
	add_animation(frames,"hurt",120,1,1)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position.y = 0
	add_child(sprite)
	sprite.play("idle")

func add_animation(frames: SpriteFrames, anim: String, row: int, count: int, fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim,fps)
	for i in range(count):
		var tex := AtlasTexture.new()
		tex.atlas = PLAYER_TEXTURE
		tex.region = Rect2(Vector2(i*8,row),Vector2(ATLAS.PLAYER_FRAME))
		frames.add_frame(anim,tex)

func configure(terrain: Array[Rect2]) -> void:
	platforms = terrain

func tick(delta: float) -> void:
	for ghost in trail:
		ghost.life -= delta
	trail = trail.filter(func(ghost): return ghost.life > 0)
	trail_timer -= delta
	if trail_enabled and dash_timer > 0 and trail_timer <= 0:
		trail.append({"position":position,"life":0.18,"flip":facing<0})
		trail_timer = 0.035
	attack_timer = maxf(0,attack_timer-delta)
	muzzle_timer = maxf(0,muzzle_timer-delta)
	invulnerable_timer = maxf(0,invulnerable_timer-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	dash_timer = maxf(0,dash_timer-delta)
	var direction := Input.get_axis("move_left","move_right")
	velocity.x = move_toward(velocity.x,direction*SPEED*speed_bonus,1300*delta)
	if direction:
		facing = signf(direction)
	if grounded:
		jumps = 0
	if Input.is_action_just_pressed("jump") and (grounded or (double_jump and jumps < 2)):
		velocity.y = JUMP_SPEED
		jumps += 1
		grounded = false
		sound_requested.emit("double_jump" if jumps > 1 else "jump")
	if dash and Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		dash_timer = 0.16
		dash_cooldown = 0.65
		sound_requested.emit("dash")
	if dash_timer > 0:
		velocity = Vector2(facing*250,0)
	else:
		velocity.y = minf(velocity.y+GRAVITY*delta,280)
	if (Input.is_action_just_pressed("attack") or (rapid_fire and Input.is_action_pressed("attack"))) and attack_timer <= 0:
		attack_timer = fire_interval
		muzzle_timer = 0.06
		attack_hit.emit()
	var old_y := position.y
	var was_grounded := grounded
	position += velocity*delta
	position.x = clampf(position.x,4,bounds.x-4)
	grounded = false
	for platform in platforms:
		if position.x+3 > platform.position.x and position.x-3 < platform.end.x and old_y+4 <= platform.position.y+0.1 and position.y+4 >= platform.position.y and velocity.y >= 0:
			position.y = platform.position.y-4
			velocity.y = 0
			grounded = true
	if grounded and not was_grounded:
		sound_requested.emit("land")
	sprite.play("hurt" if invulnerable_timer > 1.0 else "jump" if not grounded else "run" if absf(velocity.x)>2 else "idle")
	sprite.flip_h = facing < 0
	sprite.visible = invulnerable_timer <= 0 or int(invulnerable_timer*12)%2 == 0
	queue_redraw()

func take_damage(amount: int = 1) -> void:
	if invulnerable_timer > 0:
		return
	damage_received.emit()
	if shield:
		shield = false
		invulnerable_timer = 1.2
		sound_requested.emit("shield")
		return
	health = maxi(health-maxi(1,amount-armor),0)
	invulnerable_timer = 1.2
	health_changed.emit(health)

func _draw() -> void:
	for ghost in trail:
		var tint := sprite.modulate
		tint.a = ghost.life*3
		draw_texture_rect_region(PLAYER_TEXTURE,Rect2(ghost.position-position+Vector2(4 if ghost.flip else -4,-4),Vector2(-8 if ghost.flip else 8,8)),Rect2(0,88,8,8),tint)
	if shield:
		preload("res://Scripts/pixel_ui.gd").icon(self,"enemy",Vector2(-4,-17),Color("83d5ff"))
	if muzzle_timer > 0:
		draw_texture_rect_region(preload("res://Resource/UI.png"),Rect2(facing*5-1,-2,2,2),Rect2(99,19,2,2))
