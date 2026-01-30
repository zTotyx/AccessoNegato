extends CanvasLayer

# ===================== CONFIG =====================

@export var MENU_MUSIC_OFFSET_SEC: float = 1.6

@export var FADE_OUT_TIME: float = 1.5
@export var FADE_OUT_DB: float = -40.0
@export var MAIN_MUSIC_FADE_IN_TIME: float = 1.0

@export var FOTO_FADE_IN_TIME: float = 0.5
@export var FOTO_HOLD_TIME: float = 0.0
@export var FOTO_FADE_OUT_TIME: float = 0.7

# (opzionale) monologo narratrice durante transizione
@export var narratrice_vignette: Array[Texture2D] = []
@export var narratrice_side: String = "right"

# ======== PATH SCENE ========
@export var path_menu: String = "res://Menu.tscn"
@export var path_dialogo: String = "res://transizione_dialogo.tscn"
@export var path_principale: String = "res://principale.tscn"
@export var path_livello2: String = "res://livello2.tscn"
@export var path_winroom: String = "res://win_room.tscn"

# ======== FOTO PER TRANSIZIONI ========
@export var default_foto: Texture2D

@export var foto_menu_to_dialogo: Texture2D
@export var foto_dialogo_to_principale: Texture2D
@export var foto_principale_to_livello2: Texture2D
@export var foto_livello2_to_winroom: Texture2D

# (facoltativo) debug
@export var debug_prints: bool = false

# ==================================================

var old_music: AudioStreamPlayer = null
var new_music: AudioStreamPlayer = null
var _old_music_start_db: float = 0.0

@onready var foto: TextureRect = get_node_or_null("Foto") as TextureRect
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
@onready var vignette_layer: VignetteLayer = get_node_or_null("VignetteLayer") as VignetteLayer


func _ready() -> void:
	call_deferred("_ensure_menu_music_started")


func _ensure_menu_music_started() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var current_path: String = String(scene.scene_file_path)
	if current_path != path_menu:
		return

	var music: AudioStreamPlayer = _get_scene_music(scene)
	if music == null:
		return

	if not music.playing:
		music.play()

	if MENU_MUSIC_OFFSET_SEC > 0.0:
		music.seek(MENU_MUSIC_OFFSET_SEC)


func _get_scene_music(scene: Node) -> AudioStreamPlayer:
	# Richiede un AudioStreamPlayer chiamato "Music" nel root della scena
	if scene != null and scene.has_node("Music"):
		return scene.get_node("Music") as AudioStreamPlayer
	return null


func _fade_music(player: AudioStreamPlayer, from_db: float, to_db: float, time: float) -> void:
	if player == null:
		return
	if time <= 0.0:
		player.volume_db = to_db
		return

	player.volume_db = from_db
	var t: Tween = create_tween()
	t.tween_property(player, "volume_db", to_db, time)
	await t.finished


func _play_anim_and_wait(anim_name: String, backwards: bool = false) -> void:
	if anim_player == null:
		push_error("Transizione: manca AnimationPlayer")
		return
	if not anim_player.has_animation(anim_name):
		push_error("Transizione: animazione mancante: " + anim_name)
		return

	var anim: Animation = anim_player.get_animation(anim_name)
	var len: float = anim.length

	if backwards:
		anim_player.play_backwards(anim_name)
	else:
		anim_player.play(anim_name)

	await get_tree().create_timer(len).timeout


func _pick_transition_foto(target_path: String) -> Texture2D:
	var current: Node = get_tree().current_scene
	var current_path: String = ""
	if current != null:
		current_path = String(current.scene_file_path)

	if debug_prints:
		print("---- TRANSIZIONE ----")
		print("Current: ", current_path)
		print("Target : ", target_path)
		print("---------------------")

	# Menu -> Dialogo
	if current_path == path_menu and target_path == path_dialogo:
		return foto_menu_to_dialogo if foto_menu_to_dialogo != null else default_foto

	# Dialogo -> Principale
	if current_path == path_dialogo and target_path == path_principale:
		return foto_dialogo_to_principale if foto_dialogo_to_principale != null else default_foto

	# Principale -> Livello2
	if current_path == path_principale and target_path == path_livello2:
		return foto_principale_to_livello2 if foto_principale_to_livello2 != null else default_foto

	# Livello2 -> WinRoom
	if current_path == path_livello2 and target_path == path_winroom:
		return foto_livello2_to_winroom if foto_livello2_to_winroom != null else default_foto

	return default_foto


func _play_narratrice_monologue() -> void:
	if vignette_layer == null:
		return
	if narratrice_vignette.is_empty():
		return

	var seq: Array[VignetteLayer.Vignetta] = []
	for tex in narratrice_vignette:
		if tex:
			seq.append(VignetteLayer.Vignetta.new(tex, narratrice_side))

	if seq.is_empty():
		return

	vignette_layer.choice_at_index = -1
	vignette_layer.vignette = seq
	vignette_layer.start()

	await vignette_layer.dialogue_finished


func cambia_scena(percorso_nuova_scena: String) -> void:
	# --- Musica scena corrente ---
	var current_scene: Node = get_tree().current_scene
	old_music = _get_scene_music(current_scene)
	if old_music != null:
		_old_music_start_db = old_music.volume_db

	var chosen_tex: Texture2D = _pick_transition_foto(percorso_nuova_scena)

	# 1) Schermo nero
	await _play_anim_and_wait("dissolvenza", false)

	# 2) Foto fade-in
	if foto != null:
		foto.texture = chosen_tex
		foto.visible = true
		foto.modulate.a = 0.0

		var tween_in: Tween = create_tween()
		tween_in.tween_property(foto, "modulate:a", 1.0, FOTO_FADE_IN_TIME)
		await tween_in.finished
	else:
		push_error("Transizione: manca nodo 'Foto' (TextureRect).")

	# 2b) Fade-out musica vecchia, poi stop
	if old_music != null and old_music.playing:
		await _fade_music(old_music, _old_music_start_db, FADE_OUT_DB, FADE_OUT_TIME)
		old_music.stop()
		# ripristino volume originale per sicurezza
		old_music.volume_db = _old_music_start_db

	# 3) Hold foto
	if FOTO_HOLD_TIME > 0.0:
		await get_tree().create_timer(FOTO_HOLD_TIME).timeout

	# 3.5) (opzionale) monologo narratrice
	await _play_narratrice_monologue()

	# 4) Cambio scena
	get_tree().change_scene_to_file(percorso_nuova_scena)
	await get_tree().process_frame

	# 5) Foto fade-out
	if foto != null:
		var tween_out: Tween = create_tween()
		tween_out.tween_property(foto, "modulate:a", 0.0, FOTO_FADE_OUT_TIME)
		await tween_out.finished
		foto.visible = false

	# 6) Torna chiaro
	await _play_anim_and_wait("dissolvenza", true)

	# 7) Musica nuova: fade-in (vale per principale, livello2, win_room, ecc.)
	var new_scene: Node = get_tree().current_scene
	new_music = _get_scene_music(new_scene)
	if new_music != null:
		# evita doppie riproduzioni (autoplay o altre chiamate)
		if new_music.playing:
			new_music.stop()

		new_music.volume_db = FADE_OUT_DB
		new_music.play()
		await _fade_music(new_music, FADE_OUT_DB, 0.0, MAIN_MUSIC_FADE_IN_TIME)
