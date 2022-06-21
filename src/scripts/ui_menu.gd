extends PanelContainer

onready var config_menu : PopupMenu = $Title/SideMenu/HBoxContainer/Config.get_popup()

func _ready() -> void:
	config_menu.connect("id_pressed", self, "_on_config_menu_id_pressed")

func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.is_key_pressed(KEY_CONTROL):
		if event.button_index == BUTTON_WHEEL_UP:
			ui_scale_up()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			ui_scale_down()


func ui_scale_down() -> void:
	var new_shrink = max(_g.ui_shrink-0.25, 0.5)
	_g.ui_shrink = new_shrink
	SaveLoadSettings.save_settings()


func ui_scale_up() -> void:
	var new_shrink = min(_g.ui_shrink+0.25, 4)
	_g.ui_shrink = new_shrink
	SaveLoadSettings.save_settings()


func _on_ButtonDocs_pressed() -> void:
	OS.shell_open("https://resoto.com/docs")



func _on_config_menu_id_pressed(id : int) -> void:
	match id:
		0:
			pass
		1:
			API.get_model(self)
		2:
			HtmlFiles.upload_file(self)
		3:
			_g.popup_manager.open_popup("GraphPopup")

func _on_get_model_done(error:int, response) -> void:
	JavaScript.download_buffer(response.body,"model.json")


func _on_upload_file_done(_filename:String, data) -> void:
	API.patch_model(data, self)
	if _filename != "":
		_g.emit_signal("add_toast", "Model Uploaded!", "Correctly uploaded model!", 0)


func _on_patch_model_done(error:int, response) -> void:
	if typeof(response.transformed.result) == TYPE_STRING and response.transformed.result.begins_with("Error"):
		_g.emit_signal("add_toast", "Failed to patch model...", response.transformed.result, 1)
	else:
		_g.emit_signal("add_toast", "Model Patched!", "Correctly patched model!", 0)
	
