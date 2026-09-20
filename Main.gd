extends Node3D

var car: CharacterBody3D
var camera: Camera3D
var speed := 0.0
var nitro := 100.0
var race_time := 0.0
var countdown := 3.0
var finished := false
var finish_z := -500.0
var opponents: Array[Dictionary] = []
var speed_label: Label
var nitro_label: Label
var status_label: Label
var countdown_label: Label

func _ready():
    _build_world()
    _build_car()
    _build_opponents()
    _build_hud()

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.35
    mat.roughness = 0.45
    return mat

func _mesh_box(pos: Vector3, size: Vector3, color: Color):
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    mesh.material_override = _material(color)
    add_child(mesh)
    return mesh

func _build_world():
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.015, 0.02, 0.06)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.45, 0.5, 0.8)
    e.ambient_light_energy = 1.2
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -20, 0)
    sun.light_energy = 1.2
    add_child(sun)

    # Main road, with a small number of large meshes for reliable WebGL rendering.
    _mesh_box(Vector3(0, -0.25, -210), Vector3(14, 0.5, 560), Color(0.035, 0.04, 0.065))
    _mesh_box(Vector3(-7.25, 0.05, -210), Vector3(0.3, 0.35, 560), Color(0.05, 0.75, 1.0))
    _mesh_box(Vector3(7.25, 0.05, -210), Vector3(0.3, 0.35, 560), Color(1.0, 0.08, 0.45))

    for z in range(45, -501, -30):
        _mesh_box(Vector3(0, 0.03, z), Vector3(0.18, 0.06, 10), Color(0.75, 0.8, 0.95))

    for z in range(30, -501, -45):
        _mesh_box(Vector3(-11, 3.0, z), Vector3(4, 6, 5), Color(0.035, 0.045, 0.10))
        _mesh_box(Vector3(11, 4.0, z - 18), Vector3(5, 8, 5), Color(0.045, 0.03, 0.11))

    _mesh_box(Vector3(0, 0.2, finish_z), Vector3(14, 0.4, 3), Color(0.9, 0.08, 0.3))

func _make_car(color: Color, pos: Vector3):
    var body := CharacterBody3D.new()
    body.position = pos
    add_child(body)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1.8, 0.65, 3.6)
    mesh.mesh = box
    mesh.material_override = _material(color)
    body.add_child(mesh)

    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.8, 0.65, 3.6)
    col.shape = shape
    body.add_child(col)
    return body

func _build_car():
    car = _make_car(Color(0.05, 0.45, 1.0), Vector3(0, 0.55, 55))

    # Keep the camera at the root so its world transform is unambiguous in Web export.
    camera = Camera3D.new()
    add_child(camera)
    camera.position = Vector3(0, 5.0, 68.0)
    camera.look_at(Vector3(0, 0.0, 48.0), Vector3.UP)
    camera.current = true
    camera.make_current()

func _build_opponents():
    var colors = [Color(1.0, 0.1, 0.2), Color(1.0, 0.6, 0.05), Color(0.35, 0.2, 1.0)]
    var lanes = [-3.4, 0.0, 3.4]
    for i in 3:
        var opponent = _make_car(colors[i], Vector3(lanes[i], 0.55, 35 + i * 8))
        opponents.append({"node": opponent, "speed": 16.0 + i * 2.0})

func _build_hud():
    var hud := CanvasLayer.new()
    add_child(hud)

    var title := Label.new()
    title.text = "RUSHX"
    title.position = Vector2(28, 22)
    title.add_theme_font_size_override("font_size", 34)
    hud.add_child(title)

    status_label = Label.new()
    status_label.position = Vector2(28, 66)
    status_label.text = "NEON CITY  •  QUICK RACE"
    status_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(status_label)

    speed_label = Label.new()
    speed_label.position = Vector2(28, 105)
    speed_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(speed_label)

    nitro_label = Label.new()
    nitro_label.position = Vector2(1050, 30)
    nitro_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(nitro_label)

    countdown_label = Label.new()
    countdown_label.position = Vector2(585, 280)
    countdown_label.add_theme_font_size_override("font_size", 64)
    hud.add_child(countdown_label)

    var hint := Label.new()
    hint.position = Vector2(28, 675)
    hint.text = "◀ ▶ STEER     TAP CENTER = NITRO"
    hint.add_theme_font_size_override("font_size", 16)
    hud.add_child(hint)

func _physics_process(delta):
    if car == null or finished:
        return

    if countdown > 0.0:
        countdown -= delta
        countdown_label.text = str(ceil(countdown))
        if countdown <= 0.0:
            countdown_label.text = "GO!"
            status_label.text = "RACE STARTED"
        return

    if countdown_label.text != "":
        countdown_label.text = ""

    race_time += delta

    var steer := Input.get_axis("ui_left", "ui_right")
    var braking := Input.is_action_pressed("ui_down")
    var boost := Input.is_action_pressed("ui_accept") and nitro > 0.0

    var target_speed := 22.0
    if braking:
        target_speed = 7.0
    if boost:
        target_speed = 38.0
        nitro = max(0.0, nitro - 30.0 * delta)
    else:
        nitro = min(100.0, nitro + 8.0 * delta)

    speed = lerp(speed, target_speed, 3.0 * delta)
    car.velocity = Vector3(steer * 9.0, 0.0, -speed)
    car.move_and_slide()
    car.position.x = clamp(car.position.x, -5.6, 5.6)

    for data in opponents:
        var opp: CharacterBody3D = data["node"]
        opp.position.z -= float(data["speed"]) * delta
        if opp.position.z < finish_z:
            opp.position.z = 55.0

    # Camera follows the player while continuing to look down the track.
    camera.position = Vector3(car.position.x * 0.35, 5.0, car.position.z + 13.0)
    camera.look_at(Vector3(car.position.x, 0.0, car.position.z - 22.0), Vector3.UP)

    speed_label.text = "SPEED  %03d KM/H   TIME  %05.1f" % [int(speed * 5.2), race_time]
    nitro_label.text = "NITRO  %d%%" % int(nitro)

    if car.position.z <= finish_z:
        finished = true
        status_label.text = "FINISH!  TIME %.1f SEC" % race_time
        countdown_label.text = "RACE COMPLETE"

func _unhandled_input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            var width := get_viewport().get_visible_rect().size.x
            if event.position.x < width * 0.4:
                Input.action_press("ui_left")
            elif event.position.x > width * 0.6:
                Input.action_press("ui_right")
            else:
                Input.action_press("ui_accept")
        else:
            Input.action_release("ui_left")
            Input.action_release("ui_right")
            Input.action_release("ui_accept")
