extends SceneTree
## QA gate: both lobby factions must render distinct imported human GLB assets.
const LOBBY = preload("res://scripts/lobby.gd")
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _assert(ok: bool, label: String) -> void:
    if not ok:
        problems.append(label)
        push_error("TEAMCS_LOBBY_ART_ERROR: " + label)

func _run() -> void:
    var lobby = LOBBY.new()
    get_root().add_child(lobby)
    _assert(lobby.previews.size() == 2,"exactly two faction previews")
    if lobby.previews.size() >= 2:
        var ct: Node3D = lobby.previews[0]
        var t: Node3D = lobby.previews[1]
        var ct_model: Node3D = ct.get("imported_model") as Node3D
        var t_model: Node3D = t.get("imported_model") as Node3D
        _assert(is_instance_valid(ct_model),"CT imported detailed mesh")
        _assert(is_instance_valid(t_model),"T imported rigged mesh")
        _assert(bool(ct.get("prefer_detail_lod")),"CT selects tactical suit")
        _assert(not bool(t.get("prefer_detail_lod")),"T selects different soldier")
        _assert(int(ct.get("imported_mesh_count")) > 0,"CT imported mesh count")
        _assert(int(t.get("imported_mesh_count")) > 0,"T imported mesh count")
        _assert(bool(ct.get("imported_model_visible")),"CT imported mesh visibility")
        _assert(bool(t.get("imported_model_visible")),"T imported mesh visibility")
        if is_instance_valid(ct_model) and is_instance_valid(t_model):
            print("TEAMCS_LOBBY_ART_SOURCE: CT=",ct_model.scene_file_path," T=",t_model.scene_file_path)
            _assert(ct_model.scene_file_path.find("soldier_tac.glb")>=0,"CT real tactical source")
            _assert(t_model.scene_file_path.find("soldier.glb")>=0,"T real soldier source")
            _assert(ct_model.scene_file_path != t_model.scene_file_path,"different team models")
            _assert(ct_model.find_children("*","MeshInstance3D",true,false).size()>0,"CT has actual mesh geometry")
            _assert(t_model.find_children("*","MeshInstance3D",true,false).size()>0,"T has actual mesh geometry")
        var clip: AnimationPlayer = t.get("imported_anim") as AnimationPlayer
        _assert(is_instance_valid(clip),"T animation player")
        if is_instance_valid(clip):
            _assert(clip.get_animation_list().size()>1,"T contains animation clips")
    if problems.is_empty():
        print("TEAMCS_LOBBY_ART_PASS")
        quit(0)
    else:
        print("TEAMCS_LOBBY_ART_FAIL: ",problems)
        quit(1)
