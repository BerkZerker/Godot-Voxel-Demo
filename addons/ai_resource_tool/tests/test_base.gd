@tool
extends Node
class_name BaseTest

signal test_completed
var _tests_run := 0
var _tests_passed := 0
var _current_test := ""

func _init():
    print("\nRunning tests for: ", get_script().resource_path)

func run_all_tests() -> bool:
    _tests_run = 0
    _tests_passed = 0
    
    var methods = get_method_list()
    for method in methods:
        if method["name"].begins_with("test_"):
            _run_test(method["name"])
    
    print("\nResults: %d/%d tests passed" % [_tests_passed, _tests_run])
    print("----------------------------------------")
    return _tests_run == _tests_passed

func _run_test(test_name: String) -> void:
    _current_test = test_name
    print("\nRunning test: ", test_name)
    
    # Setup
    if has_method("setup"):
        call("setup")
    
    # Run test
    var passed = call(test_name)
    _tests_run += 1
    if passed:
        _tests_passed += 1
        print("✓ Test passed: ", test_name)
    else:
        push_error("✗ Test failed: " + test_name)
    
    # Teardown
    if has_method("teardown"):
        call("teardown")

func assert_true(condition: bool, message := "") -> bool:
    if not condition:
        push_error("Assertion failed in %s: %s" % [_current_test, message if message else "Expected true"])
        return false
    return true

func assert_false(condition: bool, message := "") -> bool:
    if condition:
        push_error("Assertion failed in %s: %s" % [_current_test, message if message else "Expected false"])
        return false
    return true

func assert_equal(a, b, message := "") -> bool:
    if a != b:
        push_error("Assertion failed in %s: %s. Got %s, expected %s" % [_current_test, message if message else "Values not equal", str(a), str(b)])
        return false
    return true

func assert_not_equal(a, b, message := "") -> bool:
    if a == b:
        push_error("Assertion failed in %s: %s. Both values are %s" % [_current_test, message if message else "Values should not be equal", str(a)])
        return false
    return true

func assert_null(value, message := "") -> bool:
    if value != null:
        push_error("Assertion failed in %s: %s. Got %s, expected null" % [_current_test, message if message else "Value not null", str(value)])
        return false
    return true

func assert_not_null(value, message := "") -> bool:
    if value == null:
        push_error("Assertion failed in %s: %s" % [_current_test, message if message else "Value is null"])
        return false
    return true