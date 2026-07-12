extends Node

@onready var chatBox: RichTextLabel = $Bg/ChatBox
@onready var lineEdit: LineEdit = $Bg/LineEdit
@onready var button: Button = $Bg/Button

var playerName: String = "Player 1"

func _ready() -> void:
	# Read the auto-detected identity directly from the LIB_C network engine
	if LIB_C.isPlayer2:
		playerName = "Player 2"
	else:
		playerName = "Player 1"
		
	DisplayServer.window_set_title(playerName + " - Game Window")

	LIB_C.variableSynced.connect(_onChatMessageReceived)
	lineEdit.text_submitted.connect(func(_text: String): _sendMessage())
	
	# Only connect if the editor hasn't already established the connection
	if not button.pressed.is_connected(_sendMessage):
		button.pressed.connect(_sendMessage)
	
	chatBox.append_text("[color=yellow]Welcome " + playerName + "! Chat Initialized.[/color]\n")

func _sendMessage() -> void:
	var messageText: String = lineEdit.text.strip_edges()
	if messageText.is_empty():
		return
		
	var payload: String = playerName + ": " + messageText
	chatBox.append_text("[color=cyan]You:[/color] " + messageText + "\n")
	LIB_C.syncVariableToPeer(payload)
	lineEdit.clear()

func _onChatMessageReceived(incomingText: String) -> void:
	chatBox.append_text(incomingText + "\n")
