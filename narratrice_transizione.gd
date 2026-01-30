extends Node2D

# --- CONFIG DIALOGO ---
@export var narratrice_pre: Array[Texture2D] = []   # 3
@export var player_one: Texture2D                  # 1
@export var narratrice_post: Array[Texture2D] = [] # 3

# scena da caricare alla fine
@export var main_scene_path: String = "res://Principale.tscn"

# fade out personaggi prima del cambio scena
@export var fade_time: float = 0.35

var started := false
var layer: VignetteLayer


func _ready() -> void:
	call_deferred("_start_dialogue")


func _start_dialogue() -> void:
	if started:
		return
	started = true

	layer = get_tree().current_scene.get_node_or_null("VignetteLayer") as VignetteLayer
	if layer == null:
		push_error("TransizioneDialogo: VignetteLayer non trovato nella scena corrente!")
		_go_main_scene()
		return

	# evita doppie connessioni
	if not layer.is_connected("dialogue_finished", Callable(self, "_on_dialogue_finished")):
		layer.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))

	var seq: Array[VignetteLayer.Vignetta] = []

	# 1) narratrice 3 (right)
	for tex in narratrice_pre:
		if tex:
			seq.append(VignetteLayer.Vignetta.new(tex, "right"))

	# 2)   1 (left)
	if player_one:
		seq.append(VignetteLayer.Vignetta.new(player_one, "left"))

	# 3) narratrice 3 (right)
	for tex in narratrice_post:
		if tex:
			seq.append(VignetteLayer.Vignetta.new(tex, "right"))

	if seq.is_empty():
		push_error("TransizioneDialogo: nessuna vignetta impostata (pre/player/post).")
		_go_main_scene()
		return

	layer.choice_at_index = -1 # ✅ nessuna scelta
	layer.vignette = seq
	layer.start()


func _on_dialogue_finished() -> void:
	# Fade-out dei personaggi prima di passare a principale
	var player_node: Node = get_tree().current_scene.get_node_or_null("PlayerNoMask")
	var narratrice_node: Node = get_tree().current_scene.get_node_or_null("Narratrice")

	await _fade_out(player_node, fade_time)
	await _fade_out(narratrice_node, fade_time)

	# (facoltativo) poi li rimuovo per pulizia
	if is_instance_valid(player_node):
		player_node.queue_free()
	if is_instance_valid(narratrice_node):
		narratrice_node.queue_free()

	_go_main_scene()


func _go_main_scene() -> void:
	if main_scene_path == "":
		push_error("TransizioneDialogo: main_scene_path vuoto!")
		return

	# usa l'autoload Transizione (res://Transizione.tscn) così parte anche la musica nella scena nuova
	var t: Node = get_node_or_null("/root/Transizione")
	if t != null and t.has_method("cambia_scena"):
		t.call("cambia_scena", main_scene_path)
		return

	# fallback
	get_tree().change_scene_to_file(main_scene_path)



func _fade_out(n: Node, duration: float) -> void:
	if not is_instance_valid(n):
		return

	var canvas := n as CanvasItem
	if canvas:
		var t := create_tween()
		t.tween_property(canvas, "modulate:a", 0.0, duration) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)
		await t.finished
	else:
		# se non è CanvasItem, almeno aspetta il tempo per coerenza
		await get_tree().create_timer(duration).timeout
