@tool
extends HBoxContainer

signal import_pressed
signal test_pressed

func _init():
    # Create import button
    var import_button = Button.new()
    import_button.text = "Import AI Resources"
    import_button.connect("pressed", Callable(self, "_on_import_pressed"))
    add_child(import_button)
    
    # Create test button
    var test_button = Button.new()
    test_button.text = "Run Tests"
    test_button.connect("pressed", Callable(self, "_on_test_pressed"))
    add_child(test_button)

func _on_import_pressed():
    emit_signal("import_pressed")

func _on_test_pressed():
    emit_signal("test_pressed")