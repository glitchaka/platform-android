extends Node

const TRACKS = ["title","tutorial","town","cross","nest","fungus","bone","city","palace","deep","boss"]
const EFFECTS = ["jump","double_jump","land","dash","shoot","hit","hurt","death","coin","crate","chest","switch","heal","buy","door","error","menu","accept","achievement","boss_down","key","shield","shotgun","flame","needle","tempest","phoenix"]
var music: Array[AudioStreamPlayer] = []
var voices: Array[AudioStreamPlayer] = []
var samples: Dictionary = {}
var last_played: Dictionary = {}
var current_track := ""
var active := 0
var muted := false
var ducked := false
var suspended := false
var gains := [0.0,0.0]
var transitions := 0

func _ready() -> void:
	for i in range(2):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		music.append(voice)
	for i in range(10):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -11
		add_child(voice)
		voices.append(voice)
	for id in EFFECTS:
		samples[id] = load("res://Resource/Audio/%s.wav" % id)

func select_track(id: String) -> void:
	if id == current_track or id not in TRACKS:
		return
	current_track = id
	transitions += 1
	active = 1-active
	music[active].stop()
	music[active].stream = null
	var stream: AudioStreamOggVorbis = load("res://Resource/Audio/%s.ogg" % id)
	stream.loop = true
	music[active].stream = stream
	gains[active] = 0
	music[active].volume_db = -60
	music[active].play()

func room_track(room: Dictionary, cleared: bool) -> void:
	if room.id == "nest":
		select_track("nest")
	elif room.reward == "boss" and not cleared:
		select_track("boss")
	else:
		select_track("palace" if room.zone == "aurora" else room.zone)

func play(id: String) -> void:
	if muted or suspended or not samples.has(id):
		return
	var now := Time.get_ticks_msec()
	if now-int(last_played.get(id,-1000)) < (65 if id in ["coin","hit"] else 25):
		return
	last_played[id] = now
	for voice in voices:
		if not voice.playing:
			voice.stream = samples[id]
			voice.play()
			return

func _process(delta: float) -> void:
	for i in range(2):
		gains[i] = move_toward(gains[i],1.0 if i == active else 0.0,delta*1.8)
		music[i].volume_db = -60 if muted else linear_to_db(maxf(gains[i],0.001)) + (-23 if ducked else -16)
		music[i].stream_paused = suspended
		if i != active and gains[i] == 0:
			music[i].stop()
	for voice in voices:
		voice.stream_paused = suspended
		if muted:
			voice.stop()

func shutdown() -> void:
	for voice in music+voices:
		voice.stop()
		voice.stream = null
	samples.clear()

func _exit_tree() -> void:
	shutdown()
