@tool
extends RefCounted

var import_path: String
var output_path: String

func _init():
    # Ensure paths are properly set up in project settings
    _ensure_project_settings()

func _ensure_project_settings():
    if not ProjectSettings.has_setting("ai_tool/import_path"):
        ProjectSettings.set_setting("ai_tool/import_path", "res://ai_generated/")
        
    if not ProjectSettings.has_setting("ai_tool/output_path"):
        ProjectSettings.set_setting("ai_tool/output_path", "res://generated_resources/")
        
    if not ProjectSettings.has_setting("ai_tool/log_path"):
        ProjectSettings.set_setting("ai_tool/log_path", "user://logs/")

    # Save the changes
    ProjectSettings.save()

func get_import_path() -> String:
    return ProjectSettings.get_setting("ai_tool/import_path")

func get_output_path() -> String:
    return ProjectSettings.get_setting("ai_tool/output_path")

func get_log_path() -> String:
    return ProjectSettings.get_setting("ai_tool/log_path")

func ensure_directories():
    for path in [get_import_path(), get_output_path(), get_log_path()]:
        if not DirAccess.dir_exists_absolute(path):
            DirAccess.make_dir_recursive_absolute(path)

func import_resource(_json_path: String, _output_path: String) -> bool:
    push_error("import_resource must be implemented by child class")
    return false

func read_json_file(path: String) -> Variant:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("Failed to open: " + path)
        return null
        
    var json = JSON.parse_string(file.get_as_text())
    if not json:
        push_error("Failed to parse JSON from: " + path)
        return null
        
    return json

func log_error(message: String) -> void:
    var log_file = FileAccess.open(get_log_path().path_join("import_errors.log"), FileAccess.READ_WRITE)
    if log_file:
        log_file.seek_end()
        log_file.store_line("[Error] " + message)
        log_file.close()

func log_success(message: String) -> void:
    var log_file = FileAccess.open(get_log_path().path_join("import_success.log"), FileAccess.READ_WRITE)
    if log_file:
        log_file.seek_end()
        log_file.store_line("[Success] " + message)
        log_file.close()