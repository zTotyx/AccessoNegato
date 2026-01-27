extends CanvasLayer

func cambia_scena(percorso_nuova_scena):
	# 1. LO SCHERMO DIVENTA NERO
	$AnimationPlayer.play("dissolvenza")
	await $AnimationPlayer.animation_finished
	
	# 2. FADE IN FOTO (La foto appare dolcemente)
	# Assicuriamoci che sia invisibile e trasparente all'inizio
	$Foto.visible = true
	$Foto.modulate.a = 0.0 
	
	# Creiamo il Tween per portarla da trasparente (0) a visibile (1)
	var tween_entrata = create_tween()
	tween_entrata.tween_property($Foto, "modulate:a", 1.0, 0.5) # Dura 0.5 secondi
	await tween_entrata.finished
	
	# 3. ATTESA (Tempo per ammirare la foto)
	await get_tree().create_timer(1.0).timeout
	
	# 4. CAMBIO SCENA (Mentre c'è la foto o il nero)
	# Carichiamo il livello "dietro le quinte"
	get_tree().change_scene_to_file(percorso_nuova_scena)
	
	# 5. FADE OUT FOTO (La foto sparisce dolcemente)
	var tween_uscita = create_tween()
	tween_uscita.tween_property($Foto, "modulate:a", 0.0, 0.5) # Dura 0.5 secondi
	await tween_uscita.finished
	
	# Pulizia finale
	$Foto.visible = false
	
	# 6. LO SCHERMO TORNA CHIARO
	$AnimationPlayer.play_backwards("dissolvenza")
