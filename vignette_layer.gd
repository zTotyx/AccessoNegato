class_name VignetteLayer
extends CanvasLayer

signal dialogue_finished
signal choice_selected(choice_number: int) # 1,2,3

@export var advance_action := "next_vignetta"

@onready var left_rect: TextureRect = $VignettaLeft
@onready var right_rect: TextureRect = $VignettaRight

class Vignetta:
	var texture: Texture2D
	var side: String   # "left" o "right"
	func _init(t: Texture2D, s: String):
		texture = t
		side = s

var vignette: Array[Vignetta] = []
var index := 0
var attivo := false

# scelta
var choice_at_index := -1
var awaiting_choice := false


func _ready():
	hide()
	left_rect.hide()
	right_rect.hide()


func start():
	if vignette.is_empty():
		return

	index = 0
	attivo = true
	Global.in_dialogue = true
	show()
	_show(vignette[index])


func _unhandled_input(event):
	if not attivo:
		return

	# ✅ Se siamo in modalità scelta, SPACE non fa niente, ascoltiamo 1/2/3 subito
	if awaiting_choice:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_1, KEY_KP_1: _pick(1)
				KEY_2, KEY_KP_2: _pick(2)
				KEY_3, KEY_KP_3: _pick(3)

		get_viewport().set_input_as_handled()
		return

	# avanti con space
	if event.is_action_pressed(advance_action):
		get_viewport().set_input_as_handled()
		_next()


func _pick(n: int):
	awaiting_choice = false
	emit_signal("choice_selected", n)


func _next():
	index += 1
	if index >= vignette.size():
		finish()
	else:
		_show(vignette[index])


func _show(v: Vignetta):
	left_rect.hide()
	right_rect.hide()

	if v.side == "left":
		left_rect.texture = v.texture
		left_rect.show()
	else:
		right_rect.texture = v.texture
		right_rect.show()

	# ✅ scelta attiva IMMEDIATAMENTE quando arrivi alla vignetta indovinello
	awaiting_choice = (index == choice_at_index)


func finish():
	attivo = false
	awaiting_choice = false
	Global.in_dialogue = false
	hide()
	left_rect.hide()
	right_rect.hide()
	choice_at_index = -1
	emit_signal("dialogue_finished")
