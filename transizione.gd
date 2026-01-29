extends CanvasLayer

func cambia_scena(percorso_nuova_scena):
	# --- FASE 1: CARICAMENTO (Nero -> Foto -> Nero) ---
	$AnimationPlayer.play("dissolvenza")
	await $AnimationPlayer.animation_finished
	
	# Foto Appare
	$Foto.visible = true
	$Foto.modulate.a = 0.0 
	var tween_in = create_tween()
	tween_in.tween_property($Foto, "modulate:a", 1.0, 0.5)
	await tween_in.finished
	
	# Carica scena
	get_tree().change_scene_to_file(percorso_nuova_scena)
	await get_tree().process_frame 
	
	# Foto Sparisce -> Torna il Nero
	var tween_out = create_tween()
	tween_out.tween_property($Foto, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	$Foto.visible = false
	
	# --- FASE 2: PAUSA NEL BUIO ---
	# Ho abbassato a 0.5 secondi. Se lo vuoi più lungo, aumenta questo numero.
	await get_tree().create_timer(0.5).timeout 
	
	# --- FASE 3: VIGNETTA ---
	var scena = get_tree().current_scene
	if scena and scena.has_node("VignetteLayer"):
		var vignetta = scena.get_node("VignetteLayer")
		
		# Controllo di sicurezza: La avviamo solo se non è già attiva!
		if vignetta.has_method("start"): 
			vignetta.start()
			
			# Aspettiamo la fine SOLO se la vignetta prevede il segnale
			if vignetta.has_signal("dialogo_finito"):
				await vignetta.dialogo_finito
			
	# --- FASE 4: INIZIO GIOCO ---
	$AnimationPlayer.play_backwards("dissolvenza") 
