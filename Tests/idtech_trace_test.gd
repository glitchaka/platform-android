extends SceneTree
# Ejecutar DESPUES del commit: Godot --headless --path . --script Tests/idtech_trace_test.gd
const TRACE = preload("res://Scripts/IdTech/trace2d.gd")
const ENEMY = preload("res://Scripts/enemy.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	check(is_equal_approx(TRACE.circle_fraction(Vector2.ZERO, Vector2(10, 0), Vector2(5, 0), 1.0), 0.4), "Contacto en la fraccion inicial correcta.")
	check(TRACE.circle_fraction(Vector2.ZERO, Vector2(10, 0), Vector2(5, 3), 1.0) < 0.0, "Un disparo que pasa fuera del radio no impacta.")
	check(TRACE.circle_fraction(Vector2(5, 0), Vector2(10, 0), Vector2(5, 0), 1.0) == 0.0, "Un disparo nacido dentro del blanco impacta inmediatamente.")
	check(TRACE.circle_fraction(Vector2.ZERO, Vector2.ZERO, Vector2(5, 0), 1.0) < 0.0, "Un segmento sin desplazamiento no genera impactos lejanos.")
	var near_enemy = ENEMY.new()
	near_enemy.position = Vector2(25, 0)
	var far_enemy = ENEMY.new()
	far_enemy.position = Vector2(75, 0)
	var objects := [{"kind": "crate", "position": Vector2(45, 0), "active": false}]
	var contacts: Array[Dictionary] = TRACE.impacts(Vector2.ZERO, Vector2(100, 0), [far_enemy, near_enemy], objects, 0.0, false)
	check(contacts.size() == 3, "Se registran dos enemigos y una caja.")
	if contacts.size() == 3:
		check(contacts[0].target == near_enemy and contacts[1].kind == "object" and contacts[2].target == far_enemy, "Los impactos se ordenan por fraccion real de recorrido.")
	var quests := [{"kind": "quest", "position": Vector2(30, 0), "active": false}]
	check(TRACE.impacts(Vector2.ZERO, Vector2(100, 0), [], quests, 0.0, false).is_empty(), "Los interruptores de mision bloqueados se omiten.")
	check(TRACE.impacts(Vector2.ZERO, Vector2(100, 0), [], quests, 0.0, true).size() == 1, "Los interruptores de mision habilitados reciben impacto.")
	near_enemy.free()
	far_enemy.free()
	if failures == 0:
		print("idTech 4 / trazado 2D: todas las comprobaciones pasaron.")
	quit(1 if failures > 0 else 0)
