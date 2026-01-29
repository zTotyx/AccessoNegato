extends CanvasLayer

signal dialogo_finito 

@export var vignette: Array[Texture2D] = []    
@export var personaggi: Array[Texture2D] = []
@export var advance_action := "next_vignetta" 

@onready var vignetta_rect: TextureRect = $Vignetta
@onready var personaggio_rect: TextureRect = $Personaggio
@onready var box_dialogo: Control = $BoxDialogo 

var index := 0
var attivo := false
var in_transizione := false 

func _ready():
	hide()
	box_dialogo.modulate = Color(1, 1, 1, 1)
	personaggio_rect.modulate = Color(1, 1, 1, 1)

func start():
	if vignette.is_empty():
		finish() 
		return

	index = 0
	attivo = true
	in_transizione = false
	show()
	
	# Pulizia iniziale
	personaggio_rect.texture = null
	personaggio_rect.visible = false
	
	# Primo avvio: Fade In diretto
	aggiorna_grafica(true)

func _unhandled_input(event):
	if not attivo or in_transizione:
		return
		
	if event.is_action_pressed(advance_action):
		get_viewport().set_input_as_handled()
		_next()

func _next():
	# 1. Blocchiamo gli input
	in_transizione = true
	
	# 2. FADE OUT BOX (Il box sparisce)
	var tween_out = create_tween()
	# NOTA: Qui ho messo 0.0 (invisibile) perché deve sparire
	tween_out.tween_property(box_dialogo, "modulate:a", 1.0, 1.0) 
	await tween_out.finished
	
	# 3. Avanziamo
	index += 1
	
	if index >= vignette.size():
		# --- MODIFICA RICHIESTA: DISSOLVENZA FINALE PERSONAGGIO ---
		# Siamo all'ultima vignetta. Il box è già sparito (punto 2).
		# Ora facciamo sparire anche il personaggio prima di chiudere.
		var tween_finale = create_tween()
		tween_finale.tween_property(personaggio_rect, "modulate:a", 0.0, 0.5)
		await tween_finale.finished
		# ----------------------------------------------------------
		
		finish()
	else:
		# 4. Aggiorna contenuto e FADE IN
		aggiorna_grafica(false) 
		
		# Aspettiamo il Fade In (0.5s) + un attimo di pausa
		await get_tree().create_timer(0.5).timeout
		in_transizione = false

func aggiorna_grafica(is_start: bool):
	# 1. SFONDO
	vignetta_rect.texture = vignette[index]
	
	# 2. PERSONAGGIO
	var texture_nuova = null
	if index < personaggi.size():
		texture_nuova = personaggi[index]
	
	if personaggio_rect.texture != texture_nuova:
		if texture_nuova != null:
			personaggio_rect.texture = texture_nuova
			personaggio_rect.visible = true
			
			# Fade in del personaggio se è nuovo o se è l'inizio
			if is_start or personaggio_rect.modulate.a > 0.1:
				personaggio_rect.modulate.a = 0.0 
				var tween_pers = create_tween()
				tween_pers.tween_property(personaggio_rect, "modulate:a", 1.0, 0.5)
		else:
			personaggio_rect.visible = false
			personaggio_rect.texture = null
	
	# 3. BOX DIALOGO (FADE IN)
	# Il box era a 0.0 (grazie a _next), ora lo riportiamo a 1.0 (visibile)
	box_dialogo.modulate.a = 1.0
	var tween_box = create_tween()
	tween_box.tween_property(box_dialogo, "modulate:a", 0.0, 1.0)

func finish():
	attivo = false
	in_transizione = false
	hide()
	dialogo_finito.emit()
