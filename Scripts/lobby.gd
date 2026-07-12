extends Node

# Lazy Load
@onready var chatBox: RichTextLabel = $Blur/ChatBox_Bg/ChatBox
@onready var lineEdit: LineEdit = $Blur/LineEdit_Bg/LineEdit
@onready var send: Button = $Blur/Send
@onready var exit: Button = $Blur/Exit

var player: CharacterBody2D
var playerName: String = ""

func _ready() -> void:
	# Retrieve up-to-date identity dynamically from the LIB_C autoload engine
	playerName = LIB_C.playerName
	player = get_tree().get_first_node_in_group("player")
	
	DisplayServer.window_set_title(playerName + " - Game Window")

	if not LIB_C.variableSynced.is_connected(_onChatMessageReceived):
		LIB_C.variableSynced.connect(_onChatMessageReceived)
		
	lineEdit.text_submitted.connect(func(_text: String): _sendMessage())
	
	# Connect send button dynamically
	if not send.pressed.is_connected(_sendMessage):
		send.pressed.connect(_sendMessage)
		
	# Fix core structural bug: Connect exit button explicitly to disconnect/destroy lobby node
	if not exit.pressed.is_connected(_exit):
		exit.pressed.connect(_exit)
	
	chatBox.append_text("[color=yellow]Welcome " + playerName + "! Chat Initialized.[/color]\n")
	
	# Automatically grab focus so typing is immediate and movement inputs are frozen
	lineEdit.grab_focus()

func _sendMessage() -> void:
	var messageText: String = lineEdit.text.strip_edges()
	if messageText.is_empty():
		return
		
	# Synchronize local name cache with any dynamic CLI transitions
	playerName = LIB_C.playerName
	var payload: String = playerName + ": " + messageText
	chatBox.append_text("[color=cyan]You:[/color] " + messageText + "\n")
	LIB_C.syncVariableToPeer(payload)
	lineEdit.clear()
	lineEdit.grab_focus()

func _onChatMessageReceived(incomingText: String) -> void:
	chatBox.append_text(incomingText + "\n")
	
func _exit() -> void:
	player.lobby = false;
	self.queue_free()
