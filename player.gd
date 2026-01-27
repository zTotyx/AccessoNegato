extends CharacterBody2D

@export var speed = 300.0  # Velocità di corsa
@export var jump_force = -500.0 # Potenza del salto (negativo = verso l'alto)

# Godot calcola la gravità automaticamente dalle impostazioni del progetto
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# 1. Imposta il testo (come prima)
	if Global.player_id == "":
		$NomePlayer.text = "Player"
	else:
		$NomePlayer.text = Global.player_id
	
	# 2. COMANDO NUOVO: Allinea al centro il testo
	$NomePlayer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _physics_process(delta):
	# 1. GRAVITÀ
	# Se NON siamo sul pavimento, veniamo spinti giù
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. SALTO
	# Saltiamo solo se premiamo SPAZIO ("jump") e siamo a terra
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# 3. MOVIMENTO ORIZZONTALE (Solo Sinistra/Destra)
	# get_axis restituisce: -1 (sinistra), 1 (destra) o 0 (fermo)
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
	else:
		# Se lasci i tasti, ti fermi subito (puoi cambiare speed con un numero più basso per scivolare)
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
