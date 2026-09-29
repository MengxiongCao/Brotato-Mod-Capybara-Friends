class_name CapybaraNullCrystalButton
extends CheckButton


func _ready() -> void :
	var _e = connect("toggled", self, "_on_toggled")
	pressed = ProgressData.settings.capybara_crystal_null
	RunData.capybara_null_crystal = ProgressData.settings.capybara_crystal_null


func _on_toggled(button_pressed: bool) -> void :
	RunData.capybara_null_crystal = button_pressed
	ProgressData.settings.capybara_crystal_null = button_pressed
