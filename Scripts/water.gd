# This Code Is Written By Me If You Find Any Issues Fix It
# I Ditched AI All Water Buggy Logic Is My

extends Node2D;

# Lazy Lo$SplashAnimad 
@onready var splash_anim: AnimatedSprite2D = $SplashAnim

# Exported Variables
@export var Water_Gravity: float;
@export var Water_Bounce: float;
@export var Bounce_Delay: float;

signal is_under_water_sig;

# Variables
var is_first_time_in_water: bool;
var player: CharacterBody2D;  
var o_gravity: float; 
var o_jumpV: float;
var is_splash: bool;
var is_under_water: bool;
var un_water_timer: Timer;

# Main Enrty
func _ready() -> void: 
	
	# Defaults
	is_first_time_in_water = true;
	Bounce_Delay = 1.0;
	is_splash = false;
	is_under_water = false;
	un_water_timer = Timer.new();
	
	# Connect Signal 
	is_under_water_sig.connect(is_Under_Water_Timer);
	
	# Get The Player From Tree 
	player = get_tree().get_first_node_in_group("player");
	
	# Handle Player Null
	if (!player):
		push_error("Error: Can't Find Player ! (From: water.gd)\n");
		get_tree().quit(1);
		
	# Get The Orginal Gravity And Jump
	o_gravity = player.gravity;
	o_jumpV = player.jump_velocity;
	
	# Set the Water Gravity (4x Less Of Orginal One By Default)
	Water_Gravity = o_gravity / 4.0;
	# Set the Water Bounce (2x Less of Orginal Jump Velocity)
	Water_Bounce = o_jumpV / 2.0;
	
	
# Run Many Times
func _process(_delta: float) -> void:
	if (is_splash):
		splash_anim.global_position = player.global_position;
		
	
# Signals Functions
func  _on_Body_Enter_Splash(_body: Node2D):
	if (_body.is_in_group("player") and not is_under_water):
		is_splash = true;
		splash_anim.global_position = player.global_position;
		splash_anim.visible = true;
		splash_anim.play("splash");
	else:
		splash_anim.stop();
		splash_anim.visible = false;
		is_splash = false;

func  _on_Body_Enter_Bounce(_body: Node2D):
	# Check If Player
	if (_body.is_in_group("player")):
		# Set The Flag
		is_under_water_sig.emit();
		
		# Disable Jump In Water
		player.is_in_water = true;
		
		# Check If Enter In Water From Land
		if (is_first_time_in_water):
			# Set The Gravity to Half (To Sink In Water <For Smoothness !>)
			_body.gravity = o_gravity / 2.0;
			is_first_time_in_water = false;
			
		# Bounce Delay
		await get_tree().create_timer(Bounce_Delay).timeout;
		
		# Set Water Gravity
		_body.gravity = Water_Gravity;
		
		# Bounce The Player in Water
		_body.velocity.y = Water_Bounce;
	
func  _on_Body_Exit_Bounce(_body: Node2D):
	# Check If Player
	if (_body.is_in_group("player")):
		# Set The Orginal Vars
		_body.gravity = o_gravity;
		# Set The Flag
		is_under_water = false;
		
		
# Signal Functions 
func is_Under_Water_Timer():
	if (un_water_timer != null and un_water_timer.timeout):
		is_under_water = true;
	
	# Start The Timer
	un_water_timer.start(5);
