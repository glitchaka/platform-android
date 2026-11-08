extends RefCounted
# Adaptacion del ciclo launch -> avance -> impacto -> retirada de idProjectile.
# Usa trazado por segmentos para evitar que un disparo veloz atraviese objetivos.
const TRACE = preload("res://Scripts/IdTech/trace2d.gd")

static func step(game, delta: float) -> void:
	for i in range(game.shots.size() - 1, -1, -1):
		var shot: Dictionary = game.shots[i]
		var step_time := delta
		if float(shot.delay) > 0.0:
			step_time = maxf(0.0, delta - float(shot.delay))
			shot.delay = float(shot.delay) - delta
			if step_time <= 0.0:
				continue
		var origin: Vector2 = shot.position
		var velocity: Vector2 = shot.velocity
		var distance := minf(float(shot.range), velocity.length() * step_time)
		var destination := origin + velocity.normalized() * distance
		shot.position = destination
		shot.range = maxf(0.0, float(shot.range) - distance)
		var consumed := false
		var contacts: Array[Dictionary] = TRACE.impacts(
			origin, destination, game.enemies, game.level.objects,
			float(shot.radius), game.postgame.stage == 3
		)
		for contact in contacts:
			if contact.kind == "enemy":
				var enemy = contact.target
				if not is_instance_valid(enemy) or not enemy.alive or shot.hits.has(enemy.get_instance_id()):
					continue
				shot.hits.append(enemy.get_instance_id())
				if int(shot.burn) > 0:
					enemy.ignite(int(shot.burn))
				enemy.hit(int(shot.damage))
				game.audio.play("hit")
				shot.pierce = int(shot.pierce) - 1
				if int(shot.pierce) < 0:
					consumed = true
					break
			else:
				var object: Dictionary = contact.target
				if object.active:
					continue
				if object.kind == "quest":
					game.postgame.shoot_switch(object)
					continue
				game.activate_object(object)
				if object.kind == "crate":
					game.coins += 1
					game.audio.play("crate")
				else:
					game.audio.play("switch")
					game.tell("Mecanismo activado. Busca el cofre.")
				consumed = true
				break
		if consumed or float(shot.range) <= 0.0:
			game.shots.remove_at(i)
	game.queue_redraw()
