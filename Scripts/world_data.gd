@tool
extends RefCounted

# Coordinates preserve the geography of the supplied reference, independently of camera resolution.
const ZONES = {
	"tutorial": ["Tutorial", Color("b9604c"), 0],
	"town": ["Pueblo", Color("49b9b1"), 0],
	"cross": ["Cruces", Color("389dcc"), 520],
	"fungus": ["Hongos", Color("729f58"), 0],
	"bone": ["Bosque de Huesos", Color("caa17b"), 144],
	"city": ["Ciudad en Ruinas", Color("8970bb"), 320],
	"palace": ["Palacio Blanco", Color("d4d8ce"), 520],
	"deep": ["Profundidades", Color("797582"), 320],
	"aurora": ["Jardines del Alba", Color("87d7c3"), 0]
}
var rooms: Array[Dictionary] = []
var links: Array[Dictionary] = []

func _init() -> void:
	var definitions := [
		["tutorial","tutorial",105,8,16,8,"start"], ["town","town",125,8,53,14,"rest"],
		["west_tower","cross",104,28,16,18,""], ["upper_gallery","cross",123,28,27,8,"coin"],
		["central_shaft","cross",153,28,8,28,""], ["well","cross",164,28,27,8,""],
		["nest","cross",194,28,18,8,"boss"], ["east_tower","cross",215,28,18,18,""],
		["shrine","cross",164,39,27,8,"rest"], ["east_shaft","cross",194,39,8,28,""],
		["west_road","cross",85,49,65,8,""], ["heart_room","cross",174,50,17,17,"heart"],
		["lower_gallery","cross",143,60,28,8,""], ["bone_road","cross",205,59,46,8,""],
		["fungal_road","cross",96,71,54,8,""], ["junction","cross",153,71,29,8,"coin"],
		["lower_tower","cross",185,71,18,18,""], ["fungal_drop","cross",164,82,8,18,""],
		["deep_well","cross",194,92,8,63,""], ["caverns","cross",206,82,37,13,""],
		["east_bridge","cross",246,87,18,8,""], ["east_lift","cross",267,87,8,66,""],
		["moss_gate","fungus",62,48,19,29,""], ["spore_hall","fungus",64,82,27,12,"rest"],
		["fungal_stem","fungus",94,83,10,48,""], ["canopy","fungus",107,91,34,13,"double_jump"],
		["roots","fungus",107,111,34,17,""], ["moss_depths","fungus",144,105,30,14,""],
		["root_shaft","fungus",145,123,10,35,""], ["fungal_exit","fungus",158,145,32,13,""],
		["buried_path","fungus",95,135,10,36,""], ["deep_west","deep",67,174,38,20,"heart"],
		["bone_gate","bone",255,48,19,22,""], ["ossuary","bone",278,42,28,28,"rest"],
		["rib_hall","bone",310,42,29,28,""], ["bone_crown","bone",278,27,61,11,"coin"],
		["bone_lord","bone",343,42,29,28,"boss"], ["bone_return","bone",278,74,61,10,"coin"],
		["city_gate","city",178,162,29,13,"rest"], ["reservoir","city",210,162,33,21,""],
		["city_spire","city",244,143,10,39,"dash"], ["city_square","city",257,163,32,19,""],
		["east_spire","city",279,124,10,35,""], ["archive","city",292,163,28,19,"coin"],
		["royal_spire","city",322,125,14,35,"boss"], ["city_end","city",323,184,40,11,"coin"],
		["deep_city","deep",237,187,16,30,"heart"], ["palace_gate","palace",7,92,42,12,"rest"],
		["palace_stairs","palace",35,70,10,19,""], ["palace_hall","palace",46,49,9,18,""],
		["palace_tower","palace",35,27,9,19,""], ["throne","palace",35,16,9,8,"ending"],
		["aurora_gate","aurora",250,8,28,12,"rest"],
		["aurora_garden","aurora",285,8,32,12,"coin"],
		["aurora_core","aurora",324,8,38,12,"boss"]
	]
	for d in definitions:
		rooms.append({"id": d[0], "zone": d[1], "rect": Rect2(d[2],d[3],d[4],d[5]), "reward": d[6]})
	var terrain_updates := {"moss_depths":"Musgo","deep_west":"Roca","city_square":"Ladrillo","reservoir":"Caverna","aurora_gate":"Ladrillo","aurora_garden":"Bosque","aurora_core":"Escarcha"}
	for entry in rooms:
		if terrain_updates.has(entry.id): entry["tileset"] = terrain_updates[entry.id]
	chain(["tutorial","town","well"])
	chain(["west_tower","upper_gallery","central_shaft","well","nest","east_tower"])
	chain(["west_tower","west_road","central_shaft","lower_gallery","junction","lower_tower","caverns","east_bridge","east_lift","east_spire","city_square"])
	chain(["well","shrine","east_shaft","lower_tower","deep_well","city_gate","reservoir","city_spire","city_square","archive","royal_spire","city_end"])
	chain(["east_tower","east_shaft","bone_road","bone_gate","ossuary","rib_hall","bone_lord","bone_return","ossuary"])
	chain(["ossuary","bone_crown","rib_hall"])
	chain(["shrine","heart_room","lower_gallery"])
	chain(["junction","fungal_road","spore_hall","moss_gate","west_road"])
	chain(["junction","fungal_drop","moss_depths","roots","fungal_stem","spore_hall"])
	chain(["fungal_stem","canopy","roots"])
	chain(["moss_depths","root_shaft","fungal_exit","city_gate"])
	connect_rooms("fungal_stem","buried_path","double_jump")
	connect_rooms("buried_path","deep_west")
	connect_rooms("reservoir","deep_city","dash")
	connect_rooms("moss_gate","palace_hall","keys")
	chain(["palace_gate","palace_stairs","palace_hall","palace_tower","throne"])
	connect_rooms("throne","aurora_gate","postgame")
	chain(["aurora_gate","aurora_garden","aurora_core"])
	for link in links:
		if link.a == "bone_return" or link.b == "bone_return":
			link.gate = "boss:bone_lord"
		elif link.a == "city_end" or link.b == "city_end":
			link.gate = "boss:royal_spire"

func connect_rooms(a: String, b: String, gate: String = "") -> void:
	links.append({"a":a,"b":b,"gate":gate})

func chain(ids: Array) -> void:
	for i in range(ids.size()-1):
		connect_rooms(ids[i],ids[i+1])

func room(id: String) -> Dictionary:
	for entry in rooms:
		if entry.id == id:
			return entry
	return {}

func exits(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for link in links:
		if link.a == id or link.b == id:
			result.append({"to":link.b if link.a == id else link.a,"gate":link.gate})
	# One source for physical placement, atlas labels and exported maps.
	# Keep the existing order so saved routes and return spawns stay compatible.
	for i in range(result.size()):
		result[i]["number"] = i+1
		result[i]["fraction"] = 1.0 if id == "tutorial" else float(i)/maxi(result.size()-1,1)
		result[i]["side"] = "DER" if id == "tutorial" else "IZQ" if i == 0 else "DER" if i == result.size()-1 else "CENTRO" if result.size() == 3 else "%d DE %d" % [i+1,result.size()]
	return result
