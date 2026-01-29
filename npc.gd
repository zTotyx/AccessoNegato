extends Node2D

signal npc_finished


@export var npc_intro: Texture2D
@export var player_intro_reply: Texture2D
@export var npc_riddle_block: Array[Texture2D] = []  # 3 vignette (ultima = indovinello)

@export var correct_key := 2  # ✅ 1,2,3 (tu vuoi 2)
@export var npc_correct: Texture2D
@export var npc_wrong: Texture2D

@export var tasto_interazione := "interact"

var player_in_range := false
var gia_parlato := false
var stage := "main"  # main / final

@onready var hint: Label = get_node_or_null("Visual/Label")
@onready var area: Area2D = $Area2D

var layer: VignetteLayer


func _ready():
	if hint: hint.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(_delta):
	if Global.in_dialogue or gia_parlato:
		return
	if player_in_range and Input.is_action_just_pressed(tasto_interazione):
		_start_dialogo()


func _start_dialogo():
	layer = get_tree().current_scene.get_node("VignetteLayer") as VignetteLayer
	if layer == null:
		push_error("VignetteLayer non trovato!")
		return

	if not layer.is_connected("dialogue_finished", Callable(self, "_on_dialogo_finito")):
		layer.connect("dialogue_finished", Callable(self, "_on_dialogo_finito"))
	if not layer.is_connected("choice_selected", Callable(self, "_on_choice_selected")):
		layer.connect("choice_selected", Callable(self, "_on_choice_selected"))

	var seq: Array[VignetteLayer.Vignetta] = []

	if npc_intro:
		seq.append(VignetteLayer.Vignetta.new(npc_intro, "right"))
	if player_intro_reply:
		seq.append(VignetteLayer.Vignetta.new(player_intro_reply, "left"))

	for tex in npc_riddle_block:
		if tex:
			seq.append(VignetteLayer.Vignetta.new(tex, "right"))

	layer.vignette = seq

	# ✅ indovinello = ultima vignetta del blocco
	layer.choice_at_index = seq.size() - 1

	stage = "main"
	gia_parlato = true
	if hint: hint.visible = false

	layer.start()


func _on_choice_selected(choice_number: int):
	# choice_number è 1,2,3
	var finale: Array[VignetteLayer.Vignetta] = []

	if choice_number == correct_key:
		if npc_correct:
			finale.append(VignetteLayer.Vignetta.new(npc_correct, "right"))
	else:
		if npc_wrong:
			finale.append(VignetteLayer.Vignetta.new(npc_wrong, "right"))

	layer.choice_at_index = -1
	layer.vignette = finale
	stage = "final"
	layer.start()


func _on_dialogo_finito():
	if stage == "final":
		emit_signal("npc_finished")  # ✅ avvisa main.gd
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player") and not gia_parlato:
		player_in_range = true
		if hint:
			hint.visible = true
			hint.text = "Premi E per interagire"


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if hint:
			hint.visible = false
