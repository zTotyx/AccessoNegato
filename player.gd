extends CharacterBody2D

@export var speed = 300.0
@export var jump_force = -500.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $Anim  # Questo è AnimatedSprite2D

func _ready():
	add_to_group("player")  # sempre

	if Global.player_id == "":
		$NomePlayer.text = "Player"
	else:
		$NomePlayer.text = Global.player_id

	$NomePlayer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _physics_process(delta):
	# 1. GRAVITÀ (sempre attiva)
	if not is_on_floor():
		velocity.y += gravity * delta

	# ✅ Se ci sono dialoghi/vignette attive, ignora i comandi del player
	if Global.in_dialogue:
		# (opzionale) ferma lo scorrimento orizzontale
		velocity.x = move_toward(velocity.x, 0, speed)

		move_and_slide()

		# (opzionale) metti idle mentre leggi i dialoghi
		if anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
			if anim.animation != "idle":
				anim.play("idle")
		else:
			anim.stop()
			anim.frame = 0

		return

	# 2. SALTO (solo se non siamo in dialogo)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# 3. MOVIMENTO ORIZZONTALE
	var direction = Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	# Animazioni
	if direction != 0:
		anim.flip_h = direction < 0
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
			if anim.animation != "idle":
				anim.play("idle")
		else:
			anim.stop()
			anim.frame = 0
