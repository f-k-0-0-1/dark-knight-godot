extends Node

# Globlas Vars
var MAX_ARG_SIZE: int;
var MIN_ARG_SIZE: int;
var TELE_DIS: float;
var PLAYER_TRANS_START: Vector2;
var commandsInfo: String;

func _ready() -> void:
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
	"""
