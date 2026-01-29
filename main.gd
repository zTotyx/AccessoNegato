extends Node2D

@onready var npc1 = $"NPC-Worker-1"
@onready var npc2 = $"NPC-Worker-2"

func _ready():
	npc2.visible = false
	npc2.process_mode = Node.PROCESS_MODE_DISABLED

	npc1.npc_finished.connect(_on_npc1_finished)

func _on_npc1_finished():
	npc2.visible = true
	npc2.process_mode = Node.PROCESS_MODE_INHERIT
