extends Node2D
const PIXEL = preload("res://Scripts/pixel_ui.gd")
var atlas = preload("res://Scripts/world_map.gd").new()
var game: Node2D

func _draw() -> void:
	if not game or not game.player:
		return
	if not game.menu_state.is_empty():
		draw_menu()
		return
	for heart in range(game.player.max_health):
		PIXEL.icon(self,"heart",Vector2(8+heart*8,8),Color.WHITE if heart<game.player.health else Color("63615d"))
	var title: String = game.DATA.ZONES[game.data.room(game.current).zone][0]
	title = {"Bosque de Huesos":"Huesos","Ciudad en Ruinas":"Ruinas","Palacio Blanco":"Palacio","Profundidades":"Abismo","Jardines del Alba":"Alba"}.get(title,title)
	PIXEL.shadow_text(self,Vector2(8,20),"Nido" if game.current == "nest" else title,Color(0.89,0.94,0.86,0.8))
	PIXEL.icon(self,"power",Vector2(88,8),game.ARSENAL.weapon(game.equipped_weapon).color)
	PIXEL.shadow_text(self,Vector2(100,8),"%d %d" % [game.weapons[game.equipped_weapon].level,game.durability_percent()],Color("ff9b78") if game.durability_percent()<20 else Color.WHITE)
	PIXEL.shadow_text(self,Vector2(88,20),"ARMA" if game.touch.enabled else "R ARMA",Color(0.9,0.96,0.9,0.55))
	PIXEL.icon(self,"coin",Vector2(172,8))
	PIXEL.shadow_text(self,Vector2(182,8),str(mini(game.coins,999)))
	PIXEL.icon(self,"key",Vector2(214,8))
	PIXEL.shadow_text(self,Vector2(224,8),str(game.keys))
	for i in range(3):
		PIXEL.ring(self,Vector2(249+i*27,12),10,Color(0.84,0.94,0.87,0.3),0.035)
	PIXEL.icon(self,"map",Vector2(245,8))
	PIXEL.icon(self,"goal",Vector2(272,8))
	PIXEL.shadow_text(self,Vector2(295,8),"II",Color(0.92,0.98,0.91,0.8))
	if game.shop_open:
		draw_shop()
		return
	if game.map_open:
		draw_map()
		return
	if game.journal_open:
		draw_journal()
		return
	if (game.upgrades.has("flask") or game.tonics > 0) and not game.touch.enabled:
		PIXEL.shadow_text(self,Vector2(172,21),"F%d+%d" % [game.flask_charges,game.tonics])
	if not game.postgame.trial.is_empty():
		PIXEL.shadow_text(self,Vector2(8,68),"ECO %.1fS  GOLPES %d" % [game.postgame.trial_time,game.postgame.trial_hits])
	var notice: String = game.message if game.message_time>0 else game.nearby if game.nearby_time>0 else ""
	var remaining: float = game.message_time if game.message_time>0 else game.nearby_time
	if game.touch.enabled:
		notice = notice.replace("E:","USAR:").replace("Q:","DIARIO:").replace("SHIFT o K","DASH").replace("Pulsa salto","Pulsa SALTO")
	if game.achievement_timer > 0 and game.message_time <= 0:
		notice = game.achievement_notice
		remaining = game.achievement_timer
	if not notice.is_empty() and remaining > 0:
		draw_notice(notice,minf(1,remaining/0.45))
	if not game.nearby.is_empty():
		var screen_pos: Vector2 = game.player.get_global_transform_with_canvas().origin
		var prompt_pos := screen_pos+Vector2(-4,-18)
		if prompt_pos.y > 64:
			if game.touch.enabled:
				PIXEL.icon(self,"goal",prompt_pos,Color(1,1,1,0.6))
			else:
				PIXEL.shadow_text(self,prompt_pos,"E",Color(1,1,1,0.7))

func draw_notice(notice: String, opacity: float) -> void:
	var wrapped := PIXEL.wrap(notice,35)
	var lines := wrapped.split("\n")
	var width := 0
	for line in lines:
		width = maxi(width,line.length()*8)
	# A tight translucent backing and a short fade leave the world visible.
	PIXEL.strip(self,Rect2(5,33,width+8,lines.size()*10+5),Color(0.13,0.19,0.16,0.22*opacity))
	PIXEL.shadow_text(self,Vector2(9,36),wrapped,Color(0.94,0.98,0.9,0.92*opacity))

func menu_button_rect(index: int) -> Rect2:
	return Rect2(48,61+index*24,224,20)

func centered_text(y: float, value: String, tint := Color.WHITE) -> void:
	PIXEL.text(self,Vector2((320-value.length()*8)/2.0,y),value,tint)

func draw_menu() -> void:
	var title_screen: bool = game.menu_state == "title"
	PIXEL.strip(self,Rect2(0,0,320,180),Color("272e2c") if title_screen else Color(0.13,0.15,0.14,0.84))
	PIXEL.panel(self,Rect2(16,10,288,154))
	centered_text(22,"ASHEN MERIDIAN" if title_screen else "PAUSA",PIXEL.INK)
	centered_text(38,"ELIGE TU CAMINO" if title_screen else game.room_name(game.current),PIXEL.INK)
	PIXEL.panel(self,Rect2(270,28,26,22),Color("889e86"))
	PIXEL.text(self,Vector2(275,35),"NO" if game.audio.muted else "SI",PIXEL.INK)
	PIXEL.text(self,Vector2(268,18),"VOL",PIXEL.INK)
	var options := ["NUEVO JUEGO","CARGAR","SALIR"] if title_screen else ["VOLVER AL JUEGO","MENU PRINCIPAL","SALIR DEL JUEGO"]
	var icons := ["player","save","goal"] if title_screen else ["player","map","goal"]
	for i in range(3):
		var disabled: bool = title_screen and i == 1 and not game.save_available
		var selected: bool = i == game.menu_selection
		var color := Color("535f51") if selected else Color("979b8a")
		if disabled:
			color = Color("858579")
		var rect := menu_button_rect(i)
		PIXEL.panel(self,rect,color)
		PIXEL.icon(self,icons[i],rect.position+Vector2(8,6),Color("717168") if disabled else Color.WHITE)
		PIXEL.text(self,rect.position+Vector2(32,6),options[i],Color("54544c") if disabled else Color.WHITE if selected else PIXEL.INK)
	var description: String = game.menu_message
	if description.is_empty():
		var hints := [
			"Empieza de cero. Reemplaza la partida actual." if game.save_available else "Empieza una nueva aventura.",
			"Continua desde tu ultimo descanso." if game.save_available else "No hay una partida guardada.",
			"Cerrar el juego."
		] if title_screen else ["Continua donde estas.","Guarda tu progreso y vuelve al inicio.","Guarda tu progreso y cierra el juego."]
		description = hints[game.menu_selection]
	PIXEL.text(self,Vector2(24,140),PIXEL.wrap(description,34),PIXEL.INK)
	centered_text(170,"TOCA UNA OPCION. VOL: SONIDO." if game.touch.enabled else "W S ELEGIR  ENTER ACEPTAR  V AUDIO")

func draw_shop() -> void:
	PIXEL.panel(self,Rect2(3,24,314,154))
	PIXEL.icon(self,"coin",Vector2(10,30))
	PIXEL.text(self,Vector2(24,30),"TIENDA Y TALLER",PIXEL.INK)
	PIXEL.text(self,Vector2(260,30),"PRECIO",PIXEL.INK)
	var page_start: int = (game.shop_selection/6)*6
	for i in range(page_start,mini(page_start+6,game.SHOP.ITEMS.size())):
		var item: Dictionary = game.SHOP.ITEMS[i]
		var pos := Vector2(10,46+(i-page_start)*12)
		if i == game.shop_selection:
			PIXEL.panel(self,Rect2(pos-Vector2(3,2),Vector2(306,12)),Color("656a59"))
		var text_color: Color = Color.WHITE if i == game.shop_selection else PIXEL.INK
		PIXEL.icon(self,item.icon,pos)
		PIXEL.text(self,pos+Vector2(14,0),item.name,text_color)
		var status: String = str(game.shop_price(item))
		if game.upgrades.has(item.id) or game.cosmetics.has(item.id) or game.weapons.has(item.id):
			status = "LISTO"
		elif not game.shop_unavailable(item).is_empty():
			status += "!"
		elif game.coins < game.shop_price(item) and i != game.shop_selection:
			text_color = Color("793f34")
		PIXEL.text(self,Vector2(308-status.length()*8,pos.y),status,text_color)
	var selected: Dictionary = game.SHOP.ITEMS[game.shop_selection]
	var locked: String = game.shop_unavailable(selected)
	var description: String = game.shop_message if game.shop_message_time>0 else locked if not locked.is_empty() else game.shop_description(selected)
	PIXEL.text(self,Vector2(10,120),PIXEL.wrap(description),PIXEL.INK)
	if game.touch.enabled:
		draw_footer(["SUBIR","BAJAR","COMPRAR","SALIR"],[66,70,104,74])
	else:
		PIXEL.text(self,Vector2(10,162),"W S ELEGIR  E COMPRAR  ESC SALIR",PIXEL.INK)
	PIXEL.text(self,Vector2(174,30),"%d-%d" % [page_start/6+1,int(ceil(game.SHOP.ITEMS.size()/6.0))],PIXEL.INK)

func draw_map() -> void:
	atlas.draw(game,self)

func draw_journal() -> void:
	PIXEL.panel(self,Rect2(3,24,314,154))
	for i in range(6):
		PIXEL.panel(self,Rect2(4+i*52,28,52,18),Color("737f62") if i == game.journal_tab else Color.WHITE)
		PIXEL.text(self,Vector2(6+i*52,33),["RUTA","LOGROS","ASPECT","ARMAS","TITULO","OBJETO"][i],Color.WHITE if i == game.journal_tab else PIXEL.INK)
	if game.journal_tab > 0:
		draw_collection()
		return
	if game.postgame.active():
		draw_postgame_route()
		return
	PIXEL.text(self,Vector2(10,51),PIXEL.wrap(game.objective_text()),PIXEL.INK)
	if game.progression.final_zone_unlocked():
		var destinations := ["TRONO: PUERTA DERECHA", "UMBRAL: DESCANSO Y TIENDA", "JARDIN: EXPLORACION", "SANTUARIO: GUARDIAN Y COFRE"]
		for i in range(destinations.size()):
			PIXEL.text(self,Vector2(10,103+i*12),destinations[i],PIXEL.INK)
		PIXEL.text(self,Vector2(10,160),"MAPA: BUSCA EL ICONO OBJETIVO",PIXEL.INK)
		return
	var lines: Array[String] = [
		"PUEBLO: " + ("ABIERTO" if game.progression.can_enter("town") else "MEDALLA DEL SENDERO"),
		"HONGOS: " + ("ABIERTO" if game.progression.can_enter("moss_gate") else "AMULETO DEL NIDO"),
		"HUESOS: " + ("ABIERTO" if game.progression.can_enter("bone_gate") else "BROTE VITAL"),
		"RUINAS: " + ("ABIERTO" if game.progression.can_enter("city_gate") else "LLAVE DE HUESOS"),
		"PALACIO: " + ("ABIERTO" if game.progression.can_enter("palace_hall") else "INSIGNIA REAL")
	]
	for i in range(lines.size()):
		PIXEL.text(self,Vector2(10,85+i*12),lines[i],PIXEL.INK)
	PIXEL.text(self,Vector2(10,160),"TOCA LAS PESTANAS. II: VOLVER" if game.touch.enabled else "A D PESTANAS  Q VOLVER",PIXEL.INK)

func draw_postgame_route() -> void:
	var quest: Dictionary = game.POSTGAME.QUESTS[game.postgame.stage]
	var remaining: Array = game.postgame.remaining_rooms()
	PIXEL.text(self,Vector2(10,51),"%d. %s" % [game.postgame.stage+1,quest.name],PIXEL.INK)
	var reward: Dictionary = game.PROGRESSION.POSTGAME[game.postgame.stage]
	PIXEL.text(self,Vector2(10,63),PIXEL.wrap(quest.story),PIXEL.INK)
	PIXEL.text(self,Vector2(10,87),"OBJETO: AT+%d DEF+%d" % [reward.attack,reward.armor],PIXEL.INK)
	var selection: int = mini(game.journal_selection,remaining.size()-1)
	PIXEL.text(self,Vector2(10,98),"RUTA: %d PENDIENTES  PREMIO: %d" % [remaining.size(),quest.reward],PIXEL.INK)
	for i in range(3):
		if remaining.is_empty(): break
		var index := (selection+i)%remaining.size()
		PIXEL.icon(self,"goal",Vector2(10,112+i*12))
		PIXEL.text(self,Vector2(24,112+i*12),game.room_name(remaining[index]),PIXEL.INK)
	if game.touch.enabled: draw_footer(["SUBIR","BAJAR","MAPA","SALIR"],[76,80,96,62])
	else: PIXEL.text(self,Vector2(10,161),"W S DESTINO  E MAPA  A D PESTANAS",PIXEL.INK)

func draw_collection() -> void:
	var is_style: bool = game.journal_tab == 2
	var is_weapon: bool = game.journal_tab == 3
	var is_title: bool = game.journal_tab == 4
	var is_item: bool = game.journal_tab == 5
	var entries: Array = game.journal_entries()
	var page: int = game.collection_page_size()
	var first: int = (game.journal_selection/page)*page
	if is_item:
		PIXEL.text(self,Vector2(10,51),"BONO PERMANENTE: AT+%d DEF+%d" % [game.progression.attack_bonus(),game.progression.armor_bonus()],PIXEL.INK)
	for index in range(first,mini(first+page,entries.size())):
		var entry: Dictionary = entries[index]
		var pos := Vector2(10,game.collection_row_y()+(index-first)*12)
		var selected: bool = index == game.journal_selection
		if selected:
			PIXEL.panel(self,Rect2(pos-Vector2(3,2),Vector2(306,12)),Color("737f62"))
		var done: bool = game.progression.items.has(entry.id) if is_item else game.cosmetics.has(entry.id) if is_style else game.weapons.has(entry.id) if is_weapon else game.titles.has(entry.id) if is_title else game.achievements.has(entry.id)
		PIXEL.icon(self,entry.icon if is_item else "power" if is_weapon else "player" if is_style else "goal",pos,entry.tint if is_style else Color.WHITE if done else Color("77776a"))
		PIXEL.text(self,pos+Vector2(13,0),entry.name,Color.WHITE if selected else PIXEL.INK)
		var status := ""
		if is_item:
			status = "SI" if done else "NO"
		elif is_style:
			status = "USO" if game.equipped_style == entry.id else "SI" if done else "NO"
		elif is_weapon or is_title:
			status = "USO" if entry.id == (game.equipped_weapon if is_weapon else game.equipped_title) else "SI" if done else "NO"
		else:
			status = "SI" if done else str(mini(game.MILESTONES.progress(game,entry.id),entry.target))+"-"+str(entry.target)
		PIXEL.text(self,Vector2(307-status.length()*8,pos.y),status,Color.WHITE if selected else PIXEL.INK)
	var entry: Dictionary = entries[game.journal_selection]
	var description: String = "%s\nABRE: %s\nATAQUE +%d DEFENSA +%d" % [entry.quest,entry.access,entry.attack,entry.armor] if is_item else entry.hint if is_style or is_weapon or is_title else entry.description
	if is_weapon and game.weapons.has(entry.id):
		var state: Dictionary = game.weapons[entry.id]
		var stats: Dictionary = game.weapon_stats(entry.id)
		description = "N%d DANO %d ALCANCE %d\nBALAS %d PENETRA %d\nCADENCIA %.1f-S DURABILIDAD %d\nEQUIPAR AQUI. MEJORAR EN TIENDA." % [state.level,stats.damage,stats.range,stats.pellets*stats.burst,stats.pierce,1.0/stats.interval,int(ceil(100.0*state.durability/entry.capacity))]
	if is_style and game.cosmetics.has(entry.id):
		description = "Disponible. Toca ELEGIR para equipar." if game.touch.enabled else "Disponible. E para equipar."
	elif game.journal_tab==1 and not entry.cosmetic.is_empty():
		description += " Premio: aspecto "+game.MILESTONES.style(entry.cosmetic).name+"."
	PIXEL.text(self,Vector2(10,104),PIXEL.wrap(description),PIXEL.INK)
	if game.touch.enabled:
		draw_footer(["SUBIR","BAJAR","PASIVO" if is_item else "ELEGIR","SALIR"],[76,80,96,62])
	else:
		PIXEL.text(self,Vector2(10,155),"A D PESTANAS  W S ELEGIR",PIXEL.INK)
		PIXEL.text(self,Vector2(10,166),"E EQUIPAR  Q VOLVER",PIXEL.INK)

func draw_footer(labels: Array, widths: Array) -> void:
	var x := 3.0
	for i in range(labels.size()):
		PIXEL.panel(self,Rect2(x,152,widths[i],25),Color("929d83"))
		PIXEL.text(self,Vector2(x+(widths[i]-labels[i].length()*8)/2.0,161),labels[i],PIXEL.INK)
		x += widths[i]
