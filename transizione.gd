extends CanvasLayer

# ===================== CONFIG =====================

# Se il root node del Menu si chiama diversamente, cambia questo.
@export var MENU_SCENE_NAME: String = "Menu"

# Offset (secondi) solo per la musica del menu
@export var MENU_MUSIC_OFFSET_SEC: float = 1.6

# Fade-out musica menu durante foto fabbrica
@export var FADE_OUT_TIME: float = 1.5
@export var FADE_OUT_DB: float = -40.0

# Fade-in musica principale (per non partire a palla)
@export var MAIN_MUSIC_FADE_IN_TIME: float = 1.0

# Durata foto fabbrica
@export var FOTO_FADE_IN_TIME: float = 0.5
@export var FOTO_HOLD_TIME: float = 0
@export var FOTO_FADE_OUT_TIME: float = 0.7

# ==================================================

var old_music: AudioStreamPlayer = null
var new_music: AudioStreamPlayer = null
var _old_music_start_db: float = 0.0


# ==================================================
# READY: se siamo nel menu, assicura che la musica parta subito (con offset)
# ==================================================
func _ready() -> void:
	call_deferred("_ensure_menu_music_started")


func _ensure_menu_music_started() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	if scene.name != MENU_SCENE_NAME:
		return

	var music := _get_scene_music(scene)
	if music == null:
		return

	if not music.playing:
		music.play()

	if MENU_MUSIC_OFFSET_SEC > 0.0:
		# Per sicurezza: seek dopo play
		music.seek(MENU_MUSIC_OFFSET_SEC)


# ==================================================
# Trova il player "Music" nella scena passata
# ==================================================
func _get_scene_music(scene: Node) -> AudioStreamPlayer:
	if scene and scene.has_node("Music"):
		return scene.get_node("Music") as AudioStreamPlayer
	return null


# ==================================================
# Fade musica (volume_db)
# ==================================================
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


# ==================================================
# Riproduce animazione e aspetta la durata (anti-blocco)
# ==================================================
func _play_anim_and_wait(anim_name: String, backwards: bool = false) -> void:
	if not $AnimationPlayer.has_animation(anim_name):
		push_error("Animazione mancante: " + anim_name)
		return

	var anim: Animation = $AnimationPlayer.get_animation(anim_name)
	var len: float = anim.length

	if backwards:
		$AnimationPlayer.play_backwards(anim_name)
	else:
		$AnimationPlayer.play(anim_name)

	await get_tree().create_timer(len).timeout


# ==================================================
# TRANSIZIONE COMPLETA
# ==================================================
func cambia_scena(percorso_nuova_scena: String) -> void:

	# Prendo musica scena attuale (menu)
	var current_scene: Node = get_tree().current_scene
	old_music = _get_scene_music(current_scene)
	if old_music:
		_old_music_start_db = old_music.volume_db

	# 1) Schermo nero
	await _play_anim_and_wait("dissolvenza", false)

	# 2) Foto fabbrica fade-in
	$Foto.visible = true
	$Foto.modulate.a = 0.0

	var tween_in: Tween = create_tween()
	tween_in.tween_property($Foto, "modulate:a", 1.0, FOTO_FADE_IN_TIME)
	await tween_in.finished

	# 2b) Durante la foto: fade-out veloce della musica menu, poi stop
	if old_music and old_music.playing:
		await _fade_music(old_music, _old_music_start_db, FADE_OUT_DB, FADE_OUT_TIME)
		old_music.stop()
		old_music.volume_db = _old_music_start_db

	# 3) Hold foto
	if FOTO_HOLD_TIME > 0.0:
		await get_tree().create_timer(FOTO_HOLD_TIME).timeout

	# 4) Cambio scena
	get_tree().change_scene_to_file(percorso_nuova_scena)
	await get_tree().process_frame

	# 5) Foto fade-out
	var tween_out: Tween = create_tween()
	tween_out.tween_property($Foto, "modulate:a", 0.0, FOTO_FADE_OUT_TIME)
	await tween_out.finished
	$Foto.visible = false

	# 6) Torna chiaro
	await _play_anim_and_wait("dissolvenza", true)

	# 7) Musica nuova: parte subito ma con fade-in
	var new_scene: Node = get_tree().current_scene
	new_music = _get_scene_music(new_scene)
	if new_music:
		new_music.volume_db = FADE_OUT_DB
		new_music.play()
		await _fade_music(new_music, FADE_OUT_DB, 0.0, MAIN_MUSIC_FADE_IN_TIME)
