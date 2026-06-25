extends Control

@onready var progress_bar: TextureProgressBar = $PBar

func _ready() -> void:
	# SceneManager's loader signals
	SceneManager.preload_progress_updated.connect(_on_progress_changed)
	SceneManager.all_scenes_ready.connect(_on_loading_finished)
	
	# Set bar to 0 
	progress_bar.value = 0
	
	# Wait then start loading
	await get_tree().process_frame
	SceneManager.start_global_preload()

func _on_progress_changed(per: float) -> void:
	progress_bar.value = per

func _on_loading_finished() -> void:
	SceneManager.change_scene("main_menu")
