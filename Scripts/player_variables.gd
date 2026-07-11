extends Node

# Lazy Load Variables 
@onready var heart_ui = $"../.";
@onready var sword: Node2D = $"../SwordHolder/Sword"
@onready var camera: Camera2D = $"../Camera2D"
@onready var timer_label: Label = $"../HUD/TimerLabel";
@onready var level_timer: Timer = $"../HUD/LevelTimer";
@onready var zoom_button: Button = $"../HUD/ZoomButton";
@onready var fire_point: Marker2D = $"../FirePoint";
@onready var sword_holder: Marker2D = $"../SwordHolder";
@onready var coin_counter_label: Label = $"../HUD/CoinCounter";
@onready var ability_cooldown_bar: ProgressBar = $"../HUD/AbilityCooldownBar";
@onready var sprite: AnimatedSprite2D = $"../AnimatedSprite2D";

# Audio Players Lazy Load
@onready var jump_sound: AudioStreamPlayer = $"../JumpSound";
@onready var player_hurt: AudioStreamPlayer = $"../PlayerHurt";
@onready var double_jump_sound: AudioStreamPlayer = $"../DoubleJumpSound";

# Variables Exported to the Inspector 
@export var speed: float = 650.0;
@export var gravity: float = 1500.0;
@export var max_health: int = 100;
@export var jump_velocity: float = -1150.0;
@export var sprint_speed: float = speed * 2.4;
@export var fireball_cooldown: float = 0.5;
@export var shoot_anim_duration: float = 0.2;
@export var lightning_ball_scene: PackedScene;
@export var lightning_ability_duration: float = 3.0;
@export var lightning_ability_cooldown: float = 10.0;

# Constants 
const MAX_JUMPS: int= 2;

# Variables when Node init
var fireball_scene: PackedScene;
var lightning_ball_instance: Area2D;
var cheat_command_scene: Node = null;

# Booleans
var god_mode: bool= false;
var is_dead: bool = false;
var can_shoot: bool = true;
var dash_locked: bool= false;
var is_shooting: bool = false;
var is_sprinting: bool = false;
var facing_right: bool = true;
var is_sword_swinging := false
var was_on_floor: bool = false;
var cheat_command: bool = false;
var jump_anim_played: bool = false;
var can_use_lightning: bool = true;
var is_lightning_active: bool = false;
var bonus_heart_unlocked: bool = false;

# Decimals
var jump_count: int= 0;
var move_speed: float = speed;
var time_elapsed: float = 0.0
var cooldown_remaining: float = 0.0;
var current_health: int = max_health;
var old_health: int = current_health;

# Scope Variables 
var ball: Area2D;
var fireball: Node;
var offset: Vector2;
var zoom_label: Label;
var knockback: Vector2;
var start_timer_: Timer;
var cleanup_timer: Timer; 
var saved_item: ItemData;
var input_direction: float;
var input_direction_A: float;
var time_for_3_stars: float
var time_for_2_stars: float;
var time_for_1_star: float;
