extends Node3D

var car: CharacterBody3D
var speed := 0.0
var nitro := 100.0
var race_time := 0.0
var race_started := false
var finished := false
var countdown := 3.0
var finish_z := -1000.0
var opponents := []
var hud: CanvasLayer
var speed_label: Label
var nitro_label: Label
var status_label: Label
var countdown_label: Label

func _ready():
    _build_world()
    _build_car()
    _build_opponents()
    _build_hud()

func _box(pos: Vector3, size: Vector3, color: Color, static := true):
    var body: Node3D = StaticBody3D.new() if static else Node3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 1.3
    mesh.material_override = mat
    body.add_child(mesh)
    if static:
        var col := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        col.shape = shape
        body.add_child(col)
    add_child(body)
    return body

func _build_world():
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.005, 0.008, 0.02)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.25, 0.3, 0.5)
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 0.7
    add_child(sun)

    for z in range(-1050, 81, 12):
        _box(Vector3(0, -0.15, z), Vector3(14, 0.3, 10), Color(0.025,0.03,0.05))
        _box(Vector3(-7.5, 0.15, z), Vector3(0.3, 0.3, 10), Color(0.1,0.7,1.0))
        _box(Vector3(7.5, 0.15, z), Vector3(0.3, 0.3, 10), Color(1.0,0.15,0.45))
        if z % 24 == 0:
            _box(Vector3(-12, 2.5, z), Vector3(3, 5, 3), Color(0.03,0.04,0.08))
            _box(Vector3(12, 3.5, z), Vector3(4, 7, 4), Color(0.04,0.03,0.09))
        if z % 18 == 0:
            _box(Vector3(0, 0.02, z), Vector3(0.15, 0.04, 3.2), Color(0.8,0.85,1.0))

    _box(Vector3(0, 3.0, 70), Vector3(14, 6, 0.5), Color(0.02,0.03,0.06))
    _box(Vector3(0, 3.0, finish_z), Vector3(14, 6, 0.5), Color(0.8,0.1,0.35))

func _make_car(parent: Node, color: Color, pos: Vector3):
    var body := CharacterBody3D.new()
    body.position = pos
    parent.add_child(body)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1.7, 0.55, 3.4)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.65
    mat.roughness = 0.25
    mesh.material_override = mat
    body.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.7,0.55,3.4)
    col.shape = shape
    body.add_child(col)
    return body

func _build_car():
    car = _make_car(self, Color(0.08,0.5,1.0), Vector3(0,0.65,60))
    var cam := Camera3D.new()
    cam.position = Vector3(0, 3.8, 8.5)
    cam.rotation_degrees = Vector3(-12,0,0)
    car.add_child(cam)
    cam.current = true

func _build_opponents():
    var colors = [Color(1.0,0.12,0.2), Color(1.0,0.65,0.05), Color(0.35,0.2,1.0)]
    var lanes = [-3.5, 0.0, 3.5]
    for i in 3:
        var opponent = _make_car(self, colors[i], Vector3(lanes[i],0.65,45 + i*7))
        opponents.append({"node": opponent, "speed": 15.0 + i*1.8})

func _build_hud():
    hud = CanvasLayer.new()
    add_child(hud)
    var title := Label.new()
    title.text = "RUSHX"
    title.position = Vector2(28,22)
    title.add_theme_font_size_override("font_size",32)
    hud.add_child(title)
    status_label = Label.new()
    status_label.position = Vector2(28,65)
    status_label.text = "NEON CITY  •  QUICK RACE"
    status_label.add_theme_font_size_override("font_size",18)
    hud.add_child(status_label)
    speed_label = Label.new()
    speed_label.position = Vector2(28,105)
    speed_label.add_theme_font_size_override("font_size",18)
    hud.add_child(speed_label)
    nitro_label = Label.new()
    nitro_label.position = Vector2(1000,30)
    nitro_label.add_theme_font_size_override("font_size",18)
    hud.add_child(nitro_label)
    countdown_label = Label.new()
    countdown_label.position = Vector2(570,280)
    countdown_label.add_theme_font_size_override("font_size",64)
    hud.add_child(countdown_label)
    var hint := Label.new()
    hint.position = Vector2(28,675)
    hint.text = "A/D or ◀ ▶  STEER     S  BRAKE     SPACE  NITRO"
    hint.add_theme_font_size_override("font_size",16)
    hud.add_child(hint)

func _physics_process(delta):
    if car == null or finished:
        return
    if countdown > 0:
        countdown -= delta
        countdown_label.text = str(ceil(countdown))
        if countdown <= 0:
            race_started = true
            countdown_label.text = "GO!"
            status_label.text = "RACE STARTED"
        return
    elif countdown_label.text != "":
        countdown_label.text = ""

    race_time += delta
    var steer := Input.get_axis("ui_left", "ui_right")
    var braking := Input.is_action_pressed("ui_down")
    var boost := Input.is_action_pressed("ui_accept") and nitro > 0.0
    var target := 22.0
    if braking:
        target = 6.0
    if boost:
        target = 38.0
        nitro = max(0.0, nitro - 30.0 * delta)
    else:
        nitro = min(100.0, nitro + 7.0 * delta)
    speed = lerp(speed,target,2.8*delta)
    car.velocity.z = -speed
    car.velocity.x = steer * 9.0
    car.move_and_slide()
    car.position.x = clamp(car.position.x,-5.7,5.7)

    for data in opponents:
        var opp: CharacterBody3D = data.node
        opp.position.z -= data.speed * delta
        if opp.position.z < finish_z:
            opp.position.z = 60

    speed_label.text = "SPEED  %03d KM/H   TIME  %05.1f" % [int(speed*5.2),race_time]
    nitro_label.text = "NITRO  %d%%" % int(nitro)
    if car.position.z <= finish_z:
        finished = true
        race_started = false
        status_label.text = "FINISH!  TIME %.1f SEC" % race_time
        countdown_label.text = "RACE COMPLETE"

func _unhandled_input(event):
    if event is InputEventScreenTouch and event.pressed:
        var w = get_viewport().get_visible_rect().size.x
        if event.position.x < w * 0.33:
            Input.action_press("ui_left")
        elif event.position.x > w * 0.67:
            Input.action_press("ui_right")
        else:
            Input.action_press("ui_accept")
    elif event is InputEventScreenTouch and not event.pressed:
        Input.action_release("ui_left")
        Input.action_release("ui_right")
        Input.action_release("ui_accept")
