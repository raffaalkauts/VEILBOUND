extends SceneTree

func _init() -> void:
    var scn = load("res://world/lantern_checkpoint.tscn")
    assert(scn != null, "Scene must load")
    var inst = scn.instantiate()
    assert(inst is LanternCheckpoint, "Must be LanternCheckpoint")
    print("PASS: LanternCheckpoint instantiated successfully: ", inst.name)
    print("      is_activated: ", inst.is_activated, " prompt: ", inst.prompt_label.text)
    inst.queue_free()
    quit(0)
