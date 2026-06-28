extends Node

@onready var command_box: LineEdit = $Bg/command;

# Declarations
var command : PackedStringArray;
var commands: Dictionary;

func _ready() -> void:
	# Init the dictionary
		commands = {
		"help" : [["-l", "m"],[help_line, help_multi]],
		"teleport" : [["-s", "-e"], [tele_start, tele_end]],
		"level" : [["-n", "-b"], [level_next, level_before]],
		};

# Called from the player Script
func run_command() -> void:
	# Spilt the commands via spaces
	command = command_box.text.split(" ", false);
	
	# Handle Overflow Args
	if (command.size() < Globals.MIN_ARG_SIZE):
		push_warning("Arguments are Underflow !\n");
		resetAndExit();
		return;
	elif (command.size() > Globals.MAX_ARG_SIZE):
		push_warning("Arguments are Overflow !\n");
		resetAndExit();
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
			print("Command Run!")
		else:
			push_warning("Invalid Arg: " + arg_name)
			resetAndExit();
			return;
	else:
		push_warning("Invalid Command!")
		resetAndExit();
		return;

# Todo Commands are just dummby
# Call Backs for Help
func help_line() -> void: print("help line !\n");
func help_multi() -> void: print("help multi !\n");
	
# Call Backs for Teleport
func tele_start() -> void: print("tele start !\n");
func tele_end() -> void: print("tele end !\n");

# Cal Backs for Level
func level_next() -> void: print("level next !\n");
func level_before() -> void: print("level before!\n");

# Clean up Function
func resetAndExit() -> void:
	command_box.text= "";
