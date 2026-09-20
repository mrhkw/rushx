extends Node3D

var car: CharacterBody3D
var speed := 0.0
var nitro := 100.0
var road_length := 180.0

func _ready():
    _build_world()
    _build_car()
    _build_hud()

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

    for z in range(-120, 121, 12):
        _box(Vector3(0, -0.15, z), Vector3(14, 0.3, 10), Color(0.025,0.03,0.05))
        _box(Vector3(-7.5, 0.15, z), Vector3(0.3, 0.3, 10), Color(0.1,0.7,1.0))
        _box(Vector3(7.5, 0.15, z), Vector3(0.3, 0.3, 10), Color(1.0,0.15,0.45))
        if z % 24 == 0:
            _box(Vector3(-12, 2.5, z), Vector3(3, 5, 3), Color(0.03,0.04,0.08))
            _box(Vector3(12, 3.5, z), Vector3(4, 7, 4), Color(0.04,0.03,0.09))

    for z in range(-120, 121, 8):
        _box(Vector3(0, 0.02, z), Vector3(0.15, 0.04, 3.2), Color(0.8,0.85,1.0))

func _box(pos: Vector3, size: Vector3, color: Color):
    var body := StaticBody3D.new()
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 1.5
    mesh.material_override = mat
    body.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    col.shape = shape
    body.add_child(col)
    add_child(body)

func _build_car():
    car = CharacterBody3D.new()
    car.position = Vector3(0, 0.65, 65)
    add_child(car)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1.7, 0.55, 3.4)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.08,0.5,1.0)
    mat.metallic = 0.65
    mat.roughness = 0.25
    mesh.material_override = mat
    car.add_child(mesh)

    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.7,0.55,3.4)
    col.shape = shape
    car.add_child(col)

    var cam := Camera3D.new()
    cam.position = Vector3(0, 3.8, 8.5)
    cam.rotation_degrees = Vector3(-12, 180, 0)
    car.add_child(cam)
    cam.current = true

func _physics_process(delta):
    if car == null:
        return
    var steer := Input.get_axis("ui_left", "ui_right")
    var braking := Input.is_action_pressed("ui_down")
    var boost := Input.is_action_pressed("ui_accept") and nitro > 0.0

    var target := 20.0
    if braking:
        target = 5.0
    if boost:
        target = 34.0
        nitro = max(0.0, nitro - 28.0 * delta)
    else:
        nitro = min(100.0, nitro + 8.0 * delta)

    speed = lerp(speed, target, 2.5 * delta)
    car.velocity.z = -speed
    car.velocity.x = steer * 8.0
    car.move_and_slide()
    car.position.x = clamp(car.position.x, -5.7, 5.7)

    if car.position.z < -90:
        car.position.z = 65

func _build_hud():
    var layer := CanvasLayer.new()
    add_child(layer)

    var title := Label.new()
    title.text = "RUSHX"
    title.position = Vector2(28, 22)
    title.add_theme_font_size_override("font_size", 32)
    layer.add_child(title)

    var info := Label.new()
    info.name = "Info"
    info.position = Vector2(28, 62)
    info.add_theme_font_size_override("font_size", 18)
    info.text = "NEON CITY  •  QUICK RACE"
    layer.add_child(info)

    var hint := Label.new()
    hint.position = Vector2(28, 675)
    hint.text = "A/D or ◀ ▶  STEER     S  BRAKE     SPACE  NITRO"
    hint.add_theme_font_size_override("font_size", 16)
    layer.add_child(hint)

    var nitro_label := Label.new()
    nitro_label.name = "Nitro"
    nitro_label.position = Vector2(1050, 30)
    nitro_label.add_theme_font_size_override("font_size", 18)
    nitro_label.text = "NITRO 100%"
    layer.add_child(nitro_label)
