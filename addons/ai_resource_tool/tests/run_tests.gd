@tool
extends EditorScript

# Load test files
const TEST_FILES = [
    "res://addons/ai_resource_tool/tests/test_base_handler.gd",
    "res://addons/ai_resource_tool/tests/test_scene_handler.gd"
]

func _run():
    print("\nStarting AI Resource Tool Tests")
    print("==============================")
    
    var all_passed = true
    
    # Run each test file
    for test_file in TEST_FILES:
        print("\nRunning tests from: " + test_file)
        var test_script = load(test_file)
        if test_script:
            var test = test_script.new()
            if not test.run_all_tests():
                all_passed = false
            test.free()
        else:
            push_error("Could not load test file: " + test_file)
            all_passed = false
    
    # Final results
    print("\n==============================")
    if all_passed:
        print("✓ All test suites passed!")
    else:
        push_error("✗ Some tests failed!")
    print("==============================\n")

static func run_all_tests():
    var script = load("res://addons/ai_resource_tool/tests/run_tests.gd").new()
    script._run()
    script.free()