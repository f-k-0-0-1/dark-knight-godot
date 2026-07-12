extends Node

@onready var command_box: LineEdit = $VBox/command_Box/command;
@onready var info_box: Label = $VBox/InfoBox/Label;

# Declarations
var command : PackedStringArray;
var player: CharacterBody2D; 
var flag: Area2D;
var commands: Dictionary;

func _ready() -> void:
	
	# Init refs
	player = get_tree().get_first_node_in_group("player");
	flag = null;
	
	# Init the dictionary (legacy structures preserved)
	commands = {
	"help" : [["-l", "-m"],[help_line, help_multi]],
	"teleport" : [["-s", "-e"], [tele_end, tele_start]],
	"level" : [["-n", "-b"], [level_next, level_before]],
	"clear" : [["-all"], [clear_log]],
	"shop" : [["-"], [init_shop]],
	"chat" : [["-s", "-m", "-"], [init_server, send_msg]]
	};

	# Connect background network and cloudflare signals to logging area
	if (LIB_C.has_signal("variableSynced")):
		LIB_C.variableSynced.connect(_on_network_message_received);
	if (LIB_C.has_signal("cloudflare_tunnel_ready")):
		LIB_C.cloudflare_tunnel_ready.connect(_on_cloudflare_tunnel_ready);
	if (LIB_C.has_signal("cloudflare_tunnel_failed")):
		LIB_C.cloudflare_tunnel_failed.connect(_on_cloudflare_tunnel_failed);

# Called from the player Script
func run_command() -> void:
	
	# Init player ref
	if (player == null):
		player = get_tree().get_first_node_in_group("player");
		Globals.PLAYER_TRANS_START = player.global_position;
		
	# Init flag rep
	if (flag == null):
		flag = get_tree().get_first_node_in_group("flag");

	# Intercept and process chat commands dynamically to handle arguments with spaces
	var input_text: String = command_box.text.strip_edges();
	if (input_text.begins_with("chat ")):
		handle_chat_cli_command(input_text);
		return;
	
	# Split the commands via spaces (fallback for legacy commands)
	command = command_box.text.split(" ", false);
	
	# Check for "Chat"
	if (command.size() == 0):
		log_error("Arguments are Underflow !\n");
		command_box.text= "";
		return;
	elif  (command[0] == "chat"):
		Globals.MAX_ARG_SIZE = 3;
		Globals.MIN_ARG_SIZE = 3;
	else:
		Globals.MAX_ARG_SIZE = 2;
	
	# Handle Overflow/UnderFlow Args
	if (command.size() < Globals.MIN_ARG_SIZE && command[0]):
		log_error("Arguments are Underflow !\n");
		command_box.text= "";
		return;
	
	elif (command.size() > Globals.MAX_ARG_SIZE):
		log_error("Arguments are Overflow !\n");
		command_box.text= "";
		return;
	else: pass;
	
	# Extract the info
	var cmd_name = command[0];
	var arg_name = command[1];

	# Check if the command exists
	if commands.has(cmd_name):
		var cmd_data = commands[cmd_name]; # key.value
		var args = cmd_data[0];  # key.value[0]
		var args_funcs = cmd_data[1]; # key.value[1]
		
		# Find the index of the argument
		var arg_index = args.find(arg_name);
		
		if arg_index != -1:
			
			if (cmd_name == "chat"):
				args_funcs[arg_index].call(command[2]);
			else:
				args_funcs[arg_index].call();
		else:
			if (arg_name) == "-":
				log_error("Need Arguments: Type help -m for Help\n");
				command_box.text = "";
				return;
			# Handel Other
			log_error("Invalid Arg: " + arg_name + "\n");
			command_box.text= "";
			return;
	else:
		log_error("Invalid Command!\n");
		command_box.text= "";
		return;

# Specific robust CLI parser for dynamic chat operations
func handle_chat_cli_command(text: String) -> void:
	var parts: PackedStringArray = text.split(" ", false)
	if (parts.size() < 2):
		log_error("Invalid chat command. Use 'help -m' for details.\n")
		command_box.text = ""
		return

	var sub_cmd: String = parts[1]
	
	if (sub_cmd == "-s"):
		info_box.text += "\n[System] Verifying Cloudflare installation and starting tunnel..."
		LIB_C.startCloudflareTunnel()
		command_box.text = ""
	elif (sub_cmd == "-j"):
		if (parts.size() < 3):
			log_error("Missing dynamic connection token. Format: chat -j <token_or_ip>\n")
			command_box.text = ""
			return
		var token: String = parts[2].strip_edges()
		if (token.begins_with("-")):
			token = token.substr(1)
		if (token.begins_with("\"") and token.ends_with("\"")):
			token = token.substr(1, token.length() - 2)
		info_box.text += "\n[System] Directing connection targets to: " + token
		LIB_C.connectToCloudflareServer(token)
		command_box.text = ""
		
	elif (sub_cmd == "-m"):
		var msg_prefix_1: String = "chat -m -\""
		var msg_prefix_2: String = "chat -m "
		var raw_msg: String = ""
		if (text.begins_with(msg_prefix_1) and text.ends_with("\"")):
			raw_msg = text.substr(msg_prefix_1.length(), text.length() - msg_prefix_1.length() - 1)
		elif (text.begins_with(msg_prefix_2)):
			var payload_part: String = text.substr(msg_prefix_2.length()).strip_edges()
			if (payload_part.begins_with("-")):
				payload_part = payload_part.substr(1).strip_edges()
			if (payload_part.begins_with("\"") and payload_part.ends_with("\"")):
				payload_part = payload_part.substr(1, payload_part.length() - 2)
			raw_msg = payload_part
			
		if (raw_msg.is_empty()):
			log_error("Cannot transmit blank payload.\n")
			command_box.text = ""
			return
			
		var packet: Dictionary = {
			"type": "chat",
			"sender": LIB_C.playerName,
			"msg": raw_msg
		}
		LIB_C.send_json_packet(packet)
		info_box.text += "\n[You]: " + raw_msg
		command_box.text = ""
		
	elif (sub_cmd == "-ui"):
		info_box.text += "\n[System] Managing visual frames... Checking for active Lobby instances..."
		player.lobby = true
		var existing_lobby = get_tree().root.get_node_or_null("Lobby")
		if (existing_lobby == null):
			for child in get_tree().root.get_children():
				if (child.name.to_lower() == "lobby" or child.name.to_lower().begins_with("lobby")):
					existing_lobby = child
					break
		if (existing_lobby != null):
			info_box.text += "\n[System] Active Lobby frame is already displayed."
		else:
			var lobby_scene = SceneManager.get_scene("lobby")
			if (lobby_scene != null):
				var lobby_instance = lobby_scene.instantiate()
				get_tree().root.add_child(lobby_instance)
				info_box.text += "\n[System] Lobby interface overlay spawned successfully."
				player.cheat_command = false
			else:
				log_error("SceneManager lookup returned empty for lobby scene resource.\n")
		command_box.text = ""
		
	elif (sub_cmd == "-e"):
		info_box.text += "\n[System] Initiating network termination. Stopping TCPServer and shutting down active sockets..."
		LIB_C.disconnect_all()
		command_box.text = ""
		
	elif (sub_cmd == "-n"):
		if (parts.size() < 3):
			log_error("Missing parameter name. Usage syntax: chat -n <new_name>\n")
			command_box.text = ""
			return
		var new_name: String = text.substr(text.find("-n") + 2).strip_edges()
		if (new_name.begins_with("\"") and new_name.ends_with("\"")):
			new_name = new_name.substr(1, new_name.length() - 2)
		if (new_name.is_empty()):
			log_error("Blank payloads are invalid for identity transformations.\n")
			command_box.text = ""
			return
		LIB_C.playerName = new_name
		info_box.text += "\n[System] Your dynamic identity is now: " + new_name
		command_box.text = ""
		
	else:
		log_error("Unknown argument parameters on chat command: " + sub_cmd + "\n")
		command_box.text = ""

# Signal Callback handlers
func _on_network_message_received(data: String) -> void:
	info_box.text += "\n" + data;

func _on_cloudflare_tunnel_ready(token: String) -> void:
	info_box.text += "\n[System] Connection Tunnel Online! Token has been copied to your clipboard: " + token

func _on_cloudflare_tunnel_failed(error_msg: String) -> void:
	info_box.text += "\n[Error] Cloudflare pipeline failed: " + error_msg;

# Call Backs for Help
func help_line() -> void: 
	info_box.text += "Options: " + ", ".join(commands.keys()) + "\n";
	
	# Reset Command Box
	command_box.text= "";
	
func help_multi() -> void:
	info_box.text += Globals.commandsInfo;
	
	# Reset Command Box
	command_box.text= "";
	
# Call Backs for Teleport
func tele_start() -> void: 
	player.global_position.y = flag.global_position.y;
	player.global_position.x = flag.global_position.x - Globals.TELE_DIS;
	command_box.text= "";
	
func tele_end() -> void:
	player.global_position = Globals.PLAYER_TRANS_START;
	command_box.text= "";

# Cal Backs for Level
func level_next() -> void: 
	# Current level number 
	var current_level: int = SceneManager.current_level.trim_prefix("level_").to_int();
	
	# Swith to next level
	if (current_level != SceneManager.last_level):
		SceneManager.change_scene("level_" + str(current_level + 0x1));
	else :
		SceneManager.change_scene("credits") 
	
	# Reset flags
	player = null;
	flag = null;
	
	# Reset Command Box
	command_box.text= "";
	
func level_before() -> void: 
	# Current level number
	var current_level: int = SceneManager.current_level.trim_prefix("level_").to_int();
	
	# Swith to before level
	if (current_level > 0x1):
		SceneManager.change_scene("level_" + str(current_level - 0x1));
	else :
		SceneManager.change_scene("level_" + str(current_level));
	
	# Reset flags
	player = null;
	flag = null;
	
	# Reset Command Box
	command_box.text= "";

func clear_log() -> void:
	info_box.text = "Enter:  'help -l' or 'help -m' for Help !";
	
	# Reset Command Box
	command_box.text= "";

func log_error(str_err :String) -> void:
	info_box.text += "\nError: " + str_err;
	
func init_shop() -> void:
	var shop: CanvasLayer = SceneManager.get_scene("shop_menu").instantiate()
	get_tree().current_scene.add_child(shop);
	
	# Reset Command Box
	command_box.text= "";

func init_server(_hostname: String = "") -> void:
	pass;
	
func send_msg(_msg: String = "") -> void:
	pass;
