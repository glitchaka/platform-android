extends RefCounted
# Trazado 2D inspirado en la consulta de impacto por fraccion del idTech 4.
# Referencias: neo/d3xp/Projectile.cpp y neo/d3xp/Weapon.cpp.
# Reimplementacion para Godot; no ejecuta codigo C++ del motor.

static func circle_fraction(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> float:
	var offset: Vector2 = start - center
	var direction: Vector2 = finish - start
	var radius_squared := radius * radius
	if offset.length_squared() <= radius_squared:
		return 0.0
	var a := direction.length_squared()
	if a <= 0.000001:
		return -1.0
	var b := 2.0 * offset.dot(direction)
	var c := offset.length_squared() - radius_squared
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return -1.0
	var fraction := (-b - sqrt(discriminant)) / (2.0 * a)
	return fraction if fraction >= 0.0 and fraction <= 1.0 else -1.0

static func impacts(start: Vector2, finish: Vector2, enemies: Array, objects: Array, projectile_radius: float, allow_quest: bool) -> Array[Dictionary]:
	var contacts: Array[Dictionary] = []
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		var center: Vector2 = enemy.position + Vector2(0, -4 if enemy.boss else 0)
		var radius: float = projectile_radius + (9.0 if enemy.boss else 5.0)
		var fraction := circle_fraction(start, finish, center, radius)
		if fraction >= 0.0:
			contacts.append({"fraction": fraction, "kind": "enemy", "target": enemy})
	for entry in objects:
		var object: Dictionary = entry
		if object.active or object.kind not in ["crate", "lever", "quest"]:
			continue
		if object.kind == "quest" and not allow_quest:
			continue
		var fraction := circle_fraction(start, finish, object.position, projectile_radius + 6.0)
		if fraction >= 0.0:
			contacts.append({"fraction": fraction, "kind": "object", "target": object})
	# La entidad que intersecta primero el segmento tiene prioridad, no la que
	# esta mas cerca del punto de salida o aparece antes en el arreglo.
	contacts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if absf(a.fraction - b.fraction) < 0.000001:
			return a.kind == "object" and b.kind != "object"
		return a.fraction < b.fraction
	)
	return contacts
