extends Node

# Lazy Load
@onready var chatBox: RichTextLabel = $Blur/ChatBox_Bg/ChatBox
@onready var lineEdit: LineEdit = $Blur/LineEdit_Bg/LineEdit
@onready var send: Button = $Blur/Send
@onready var exit: Button = $Blur/Exit

var player: CharacterBody2D
var playerName: String = ""

func _ready() -> void:
	playerName = LIB_C.playerName
	player = get_tree().get_first_node_in_group("player")
	DisplayServer.window_set_title(playerName + " - Game Window")
	
	if not LIB_C.chat_received.is_connected(_onChatMessageReceived):
		LIB_C.chat_received.connect(_onChatMessageReceived)
		
	lineEdit.text_submitted.connect(func(_text: String): _sendMessage())
	
	if not send.pressed.is_connected(_sendMessage):
		send.pressed.connect(_sendMessage)
		
	if not exit.pressed.is_connected(_exit):
		exit.pressed.connect(_exit)
		
	chatBox.append_text("[color=yellow]Welcome " + playerName + "! Chat Initialized.[/color]\n")
	lineEdit.grab_focus()

func _sendMessage() -> void:
	var messageText: String = lineEdit.text.strip_edges()
	if messageText.is_empty():
		return
		
	playerName = LIB_C.playerName
	var packet: Dictionary = {
		"type": "chat",
		"sender": playerName,
		"msg": messageText
	}
	
	chatBox.append_text("[color=cyan]You:[/color] " + messageText + "\n")
	LIB_C.send_json_packet(packet)
	lineEdit.clear()
	lineEdit.grab_focus()

func _onChatMessageReceived(sender: String, msg: String) -> void:
	if sender == playerName:
		return # Prevent double printing local messages
	chatBox.append_text("[color=cyan]" + sender + ":[/color] " + msg + "\n")

func _exit() -> void:
	player.lobby = false
	self.queue_free()
