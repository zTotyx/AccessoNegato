extends Control

func _ready():
	# 1. Collegamento Bottone (come prima)
	$VBoxContainer/Button.pressed.connect(_on_gioca_pressed)
	
	# 2. NUOVO: Collegamento Tasto Invio sulla tastiera
	# "text_submitted" è il segnale che parte quando premi Invio nella casella
	$VBoxContainer/LineEdit.text_submitted.connect(_on_invio_premuto)

	# Pulizia errore iniziale
	$VBoxContainer/LabelErrore.text = ""

# --- FUNZIONE PONTE ---
# Questa serve perché il segnale "text_submitted" invia del testo, 
# ma la nostra funzione "_on_gioca_pressed" non vuole argomenti.
# Questa funzione prende il testo (e lo ignora) e chiama quella principale.
func _on_invio_premuto(new_text):
	_on_gioca_pressed()

# --- FUNZIONE PRINCIPALE ---
func _on_gioca_pressed():
	var nome_inserito = $VBoxContainer/LineEdit.text
	
	if nome_inserito == "":
		$VBoxContainer/LabelErrore.text = "Attenzione: Inserisci un nome per giocare!"
		$VBoxContainer/LabelErrore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return 
		
	Global.player_id = nome_inserito
	Transizione.cambia_scena("res://principale.tscn")
