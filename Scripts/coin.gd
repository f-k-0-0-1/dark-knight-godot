extends Area2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coin_sound: AudioStreamPlayer = $CoinSound

signal coin_collected

var sync_id: String = ""
var is_syncing: bool = false

func _ready() -> void:
	sync_id = str(get_path())
	body_entered.connect(_on_body_entered)
	
	if LIB_C != null:
		if not LIB_C.coin_sync_received.is_connected(_on_coin_sync_received):
			LIB_C.coin_sync_received.connect(_on_coin_sync_received)

func _on_body_entered(body: Node2D) -> void:
	if is_syncing:
		return
		
	if body.is_in_group("player") and body.is_local:
		is_syncing = true
		anim_sprite.visible = false
		$CollisionShape2D.call_deferred("set_disabled", true)
		
		if coin_sound:
			coin_sound.play()
			
		Globals.add_level_coin()
		coin_collected.emit()
		
		if LIB_C != null:
			var packet: Dictionary = {
				"type": "coin_sync",
				"sender": LIB_C.playerName,
				"id": sync_id
			}
			LIB_C.send_json_packet(packet)
			
		await get_tree().create_timer(0.5).timeout
		queue_free()

func _on_coin_sync_received(coin_id: String) -> void:
	if coin_id == sync_id and not is_syncing:
		is_syncing = true
		anim_sprite.visible = false
		$CollisionShape2D.call_deferred("set_disabled", true)
		await get_tree().create_timer(0.1).timeout
		queue_free()
