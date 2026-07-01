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
	player = null;
	flag = null;
	
	# Init the dictionary
	commands = {
	"help" : [["-l", "-m"],[help_line, help_multi]],
	"teleport" : [["-s", "-e"], [tele_end, tele_start]],
	"level" : [["-n", "-b"], [level_next, level_before]],
	"clear" : [["-all"], [clear_log]],
	"shop" : [["-"], [init_shop]]
	};

# Called from the player Script
func run_command() -> void:
	
	# Init player ref
	if (player == null):
		player = get_tree().get_first_node_in_group("player");
		Globals.PLAYER_TRANS_START = player.global_position;
		
	# Init flag rep
	if (flag == null):
		flag = get_tree().get_first_node_in_group("flag");
	
	# Spilt the commands via spaces
	command = command_box.text.split(" ", false);
	
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
			# Call the function
			args_funcs[arg_index].call()
		else:
			if (arg_name) == "-":
				log_error("Need Arguments: Type help -m for Help\n")
				command_box.text = "";
				return;
			# Handel Other
			log_error("Invalid Arg: " + arg_name + "\n")
			command_box.text= "";
			return;
	else:
		log_error("Invalid Command!\n")
		command_box.text= "";
		return;

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
	player.global_position.x = flag.global_position.x - Globals.TELE_DIS
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
