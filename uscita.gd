extends Area2D

# Creiamo la casella per trascinare il livello 2
@export_file("*.tscn") var livello_successivo

func _ready():
	# Colleghiamo il segnale automaticamente
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Se entra il Player...
	if body.name == "Player":
		print("Vittoria! Cambio livello...")
		call_deferred("cambia_scena")

func cambia_scena():
	# Se hai messo il file nella casella, carica la scena
	if livello_successivo:
		Transizione.cambia_scena("res://livello2.tscn")
	else:
		print("ERRORE: Hai dimenticato di inserire il Livello 2 nell'Inspector!")
