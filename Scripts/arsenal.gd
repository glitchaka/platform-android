extends RefCounted

# All visuals use the original atlases. Levels are per weapon, never shared.
const WEAPONS = [
	{"id":"pistol","name":"PISTOLA","hint":"Arma inicial. Nivel 2: atraviesa enemigos.","color":Color("ffe5a0"),"capacity":240,"repair":12},
	{"id":"shotgun","name":"ESCOPETA","hint":"Tienda: 42 monedas tras liberar el Nido.","color":Color("ffb578"),"capacity":150,"repair":20},
	{"id":"flame","name":"LANZALLAMAS","hint":"Tienda: 60 monedas tras vencer a Huesos.","color":Color("ff7964"),"capacity":480,"repair":26},
	{"id":"needle","name":"AGUJA DEL ALBA","hint":"Vence los 3 ecos sin recibir golpes. Rayo penetrante.","color":Color("8ee8ff"),"capacity":180,"repair":28},
	{"id":"tempest","name":"TEMPESTAD","hint":"Vence cada eco en 12 segundos. Rafaga de 3 balas.","color":Color("c6acff"),"capacity":210,"repair":30},
	{"id":"phoenix","name":"FENIX","hint":"Supera la prueba final sin curarte. Tres chorros de fuego.","color":Color("ffd26f"),"capacity":540,"repair":32}
]
const TITLES = [
	{"id":"none","name":"SIN TITULO","hint":"Sin bonificaciones."},
	{"id":"ranger","name":"CAMINANTE","hint":"Mision 1. Velocidad de carrera +12%."},
	{"id":"keeper","name":"CUSTODIO","hint":"Mision 2. Desgaste de armas -20%."},
	{"id":"slayer","name":"CAZADOR DE ECOS","hint":"Mision 3. Dano directo +1."},
	{"id":"smith","name":"MAESTRO ARTESANO","hint":"Mision 4. Reparaciones -25%."},
	{"id":"sovereign","name":"DEL MERIDIANO","hint":"Mision 5. Cadencia +12%, alcance +10%."},
	{"id":"untouched","name":"INTOCABLE","hint":"Tres ecos sin golpes. Alcance +20%."},
	{"id":"swift","name":"RELAMPAGO","hint":"Tres ecos en 12s cada uno. Cadencia +20%."},
	{"id":"immortal","name":"INQUEBRANTABLE","hint":"Prueba final sin curas. Dano +1, desgaste -15%."}
]

static func weapon(id: String) -> Dictionary:
	for entry in WEAPONS:
		if entry.id == id: return entry
	return WEAPONS[0]

static func stats(id: String, level: int) -> Dictionary:
	var s := {"damage":1+level,"interval":0.25-level*0.02,"range":190.0+level*40,"speed":290.0,"pellets":1,"spread":0.0,"pierce":maxi(0,level-1),"burn":0,"automatic":false,"burst":1,"radius":2.0,"kind":"bullet"}
	match id:
		"shotgun":
			s.merge({"damage":1+level,"interval":0.65-level*0.055,"range":110.0+level*26,"pellets":3+(2 if level==3 else 0),"spread":0.20+level*0.035,"pierce":0},true)
		"flame","phoenix":
			s.merge({"damage":1+level/2,"interval":0.13-level*0.01,"range":56.0+level*16,"speed":130.0,"pierce":8,"burn":1+level/2,"automatic":true,"radius":4.0,"kind":"flame"},true)
			if id == "phoenix": s.merge({"pellets":3,"spread":0.22,"burn":2+level,"range":78.0+level*18},true)
		"needle":
			s.merge({"damage":6+level*2,"interval":0.8-level*0.065,"range":340.0+level*60,"speed":510.0,"pierce":4+level,"radius":2.5,"kind":"lance"},true)
		"tempest":
			s.merge({"damage":2+level,"interval":0.48-level*0.045,"range":230.0+level*35,"speed":350.0,"burst":3,"automatic":true,"pierce":1 if level>=2 else 0},true)
	return s

static func fresh() -> Dictionary:
	return {"pistol":{"level":0,"durability":240.0}}

static func restore(saved: Dictionary) -> Dictionary:
	var result := fresh()
	for entry in WEAPONS:
		if saved.get(entry.id) is Dictionary:
			var state: Dictionary = saved[entry.id]
			result[entry.id] = {"level":clampi(int(state.get("level",0)),0,3),"durability":clampf(float(state.get("durability",entry.capacity)),0,entry.capacity)}
	return result
