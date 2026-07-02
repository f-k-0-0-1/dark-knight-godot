extends Node;

# Globlas Vars
var MAX_ARG_SIZE: int;
var MIN_ARG_SIZE: int;
var TELE_DIS: float;
var PLAYER_TRANS_START: Vector2;
var commandsInfo: String;

var player_coins: int = 0
signal coins_updated(new_total: int)

var level_coins: int = 0
signal level_coins_updated(new_total: int)

func _ready() -> void:
	load_coins()
	MAX_ARG_SIZE = 2;
	MIN_ARG_SIZE = 2;
	TELE_DIS = 1200.00;
	PLAYER_TRANS_START = Vector2(0, 0);

	# Docs for commands
	commandsInfo = """
	\nHere are Some Useful Commands\n
	1. Help -l  -> For Sinlge Line Help Commands\n
	2. Help -m  -> For Multi Line Help Commands\n 
	3. teleport -s -> Teleport to Start\n
	4. teleport -e -> Teleport to End\n
	5. level -b -> Bypass Level Behind\n
	6. level -n -> Bypass to Next Level\n
	7. clear -all ->  To Clear The Commands & Error Logs\n
	8. shop  - (use '-' for no args) -> To Open Shop Menu\n
	"""

# Use this when collecting coins in a level
func add_level_coin():
	level_coins += 1
	level_coins_updated.emit(level_coins)
	
	# Also add it to the permanent wallet for the Global saving system
	player_coins += 1
	coins_updated.emit(player_coins)
	save_coins()

# Call this when the level starts to reset the counter
func reset_level_coins():
	level_coins = 0
	level_coins_updated.emit(level_coins)

func save_coins():
	var config = ConfigFile.new()
	var file_path = "user://save_data.ini"
	
	config.load(file_path)
	config.set_value("player_data", "coins", player_coins)
	config.save(file_path)

func load_coins():
	var config = ConfigFile.new()
	var file_path = "user://save_data.ini"
	
	if config.load(file_path) == OK:
		player_coins = config.get_value("player_data", "coins", 0)
	else:
		player_coins = 0
