extends Node

# Lazy Load player script
@onready var player = $"..";
@onready var pvar = $"../Variables";

# Signal Function For Coin
func _update_coin_ui(new_total: int) -> void:
	if (pvar.coin_counter_label):
		pvar.coin_counter_label.text = str(new_total);

# Signal Function For Zoom
func _on_zoom_button_pressed() -> void:
	if player.camera:
		pvar.zoom_label = player.camera.toggle_zoom();
		pvar.zoom_button.text = player.zoom_label;

# Signal Function for Dash Animation Finished
func _on_dash_anim_finished() -> void:
	pvar.dash_locked = false;  # Unlock the animation
	
	# Immediately switch back to a valid animation state based on movement
	if (abs(player.velocity.x) > 10.0):
		pvar.sprite.play("walk");
	else:
		pvar.sprite.play("idle");

# Signal Function For Weapon Equipped		
func _on_weapon_equipped(item_data: ItemData) -> void:
	pvar.sword.equip_weapon(item_data);
	
	# Connect sword swing signals to lock/unlock player movement
	if (not pvar.sword.swing_started.is_connected(_on_sword_swing_started)):
		pvar.sword.swing_started.connect(_on_sword_swing_started);
	if (not player.sword.swing_finished.is_connected(_on_sword_swing_finished)):
		pvar.sword.swing_finished.connect(_on_sword_swing_finished);

# Signal Function for Lightning Timer End
func _on_lightning_ability_end() -> void:
	pvar.is_lightning_active = false;
	
	if (is_instance_valid(pvar.lightning_ball_instance)):
		pvar.lightning_ball_instance.visible = false;
		if (pvar.lightning_ball_instance.has_method("deactivate")):
			pvar.lightning_ball_instance.deactivate();

# Signal Function for Lightning CoolDown Timer
func _on_lightning_cooldown_timeout() -> void:
	pvar.can_use_lightning = true;

# Signal Function for Shoot Animation End	
func _on_shoot_anim_end() -> void:
	pvar.is_shooting = false;
	if (abs(player.velocity.x) > 10.0):
		pvar.sprite.play("walk");
	else:
		pvar.sprite.play("idle");

# Signal Function for FireBall Cooldown
func _on_fireball_cooldown_timeout() -> void:
	pvar.can_shoot = true;

# Signal Function for Sword Swing
func _on_sword_swing_started() -> void:
	pvar.is_sword_swinging = true;

# Signal Function for Sword Swing Finished
func _on_sword_swing_finished() -> void:
	pvar.is_sword_swinging = false;
