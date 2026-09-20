extends Node3D

# RUSHX - 3D Arcade Racing Vertical Slice
# Menus, garage, 3 original tracks, 3D cars, AI, nitro, race HUD and results.
var state := "menu"
var selected_track := 0
var selected_car := 0
var car: CharacterBody3D
var camera: Camera3D
var speed := 0.0
var nitro := 100.0
var race_time := 0.0
var countdown := 3.0
var finished := false
var finish_z := -900.0
var opponents: Array[Dictionary] = []
var world_nodes: Array[Node] = []
var ui: CanvasLayer
var menu_box: VBoxContainer
var title_label: Label
var info_label: Label
var race_hud: Control
var speed_label: Label
var nitro_label: Label
var race_label: Label
var countdown_label: Label
var result_panel: PanelContainer
var track_names = ["NEON CITY", "DESERT HIGHWAY", "MOUNTAIN RUN"]
var track_colors = [Color(0.08,0.8,1.0), Color(1.0,0.48,0.08), Color(0.5,0.65,1.0)]
var car_colors = [Color(0.05,0.45,1.0), Color(1.0,0.12,0.18), Color(0.75,0.1,1.0), Color(1.0,0.62,0.05), Color(0.1,0.95,0.7)]

func _ready():
    _setup_ui()
    _show_menu()

func _mat(color: Color, metallic := 0.2, rough := 0.45) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = rough
    return m

func _box(parent: Node, pos: Vector3, size: Vector3, color: Color, bevel := 0.0) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var b := BoxMesh.new()
    b.size = size
    if bevel > 0.0:
        b.material = _mat(color, 0.35, 0.28)
    n.mesh = b
    n.position = pos
    n.material_override = _mat(color, 0.35, 0.3)
    parent.add_child(n)
    world_nodes.append(n)
    return n

func _cylinder(parent: Node, pos: Vector3, radius: float, height: float, color: Color, rot := Vector3.ZERO) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var c := CylinderMesh.new()
    c.top_radius = radius
    c.bottom_radius = radius
    c.height = height
    n.mesh = c
    n.position = pos
    n.rotation = rot
    n.material_override = _mat(color, 0.25, 0.5)
    parent.add_child(n)
    world_nodes.append(n)
    return n

func _clear_world():
    for n in world_nodes:
        if is_instance_valid(n):
            n.queue_free()
    world_nodes.clear()
    if is_instance_valid(car):
        car.queue_free()
    car = null
    for d in opponents:
        if is_instance_valid(d["node"]):
            d["node"].queue_free()
    opponents.clear()
    if is_instance_valid(camera):
        camera.queue_free()
    camera = null

func _make_car(color: Color, pos: Vector3, scale := 1.0) -> CharacterBody3D:
    var body := CharacterBody3D.new()
    body.position = pos
    body.scale = Vector3.ONE * scale
    add_child(body)
    world_nodes.append(body)

    var main := _box(body, Vector3(0,0.48,0), Vector3(1.9,0.62,3.7), color)
    var cabin := _box(body, Vector3(0,0.91,0.15), Vector3(1.38,0.48,1.65), color.darkened(0.18))
    var glass := _box(body, Vector3(0,1.03,-0.02), Vector3(1.15,0.2,1.25), Color(0.04,0.09,0.16))
    var front := _box(body, Vector3(0,0.48,-1.87), Vector3(1.45,0.16,0.08), Color(0.82,0.95,1.0))
    var rear := _box(body, Vector3(0,0.48,1.87), Vector3(1.45,0.16,0.08), Color(1.0,0.08,0.08))
    for x in [-0.82,0.82]:
        for z in [-1.2,1.2]:
            _cylinder(body, Vector3(x,0.27,z), 0.28, 0.18, Color(0.015,0.015,0.02), Vector3(0,0,PI/2))
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.8,0.9,3.5)
    col.shape = shape
    col.position.y = 0.5
    body.add_child(col)
    return body

func _build_environment(track: int):
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = [Color(0.008,0.015,0.045), Color(0.08,0.035,0.015), Color(0.03,0.055,0.09)][track]
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = [Color(0.35,0.45,0.8), Color(0.85,0.58,0.35), Color(0.48,0.58,0.9)][track]
    e.ambient_light_energy = 1.25
    env.environment = e
    add_child(env)
    world_nodes.append(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-25,0)
    sun.light_energy = 1.5
    add_child(sun)
    world_nodes.append(sun)

    var road_color = [Color(0.025,0.035,0.06), Color(0.18,0.12,0.075), Color(0.07,0.08,0.095)][track]
    _box(self, Vector3(0,-0.3,-430), Vector3(18,0.6,980), road_color)
    _box(self, Vector3(-9.4,0,-430), Vector3(0.38,0.45,980), track_colors[track])
    _box(self, Vector3(9.4,0,-430), Vector3(0.38,0.45,980), track_colors[track])

    for z in range(45,-901,-28):
        _box(self, Vector3(0,0.03,z), Vector3(0.22,0.07,12), Color(0.92,0.94,1.0))
    for z in range(25,-901,-45):
        var h = 5.0 + float((abs(z) / 45) as int % 4) * 2.0
        if track == 0:
            _box(self, Vector3(-14,h/2,z), Vector3(5,h,7), Color(0.035,0.045,0.12))
            _box(self, Vector3(14,h/2,z-18), Vector3(5,h,7), Color(0.055,0.03,0.12))
            _box(self, Vector3(-14,h+0.2,z), Vector3(3.2,0.12,0.25), track_colors[track])
        elif track == 1:
            _cylinder(self, Vector3(-15,3,z), 2.5, 6.0, Color(0.12,0.22,0.08))
            _cylinder(self, Vector3(15,3,z-12), 3.0, 6.0, Color(0.16,0.25,0.09))
        else:
            _box(self, Vector3(-14,h/2,z), Vector3(6,h,7), Color(0.11,0.14,0.2))
            _box(self, Vector3(14,h/2,z-16), Vector3(6,h,7), Color(0.13,0.16,0.22))
    _box(self, Vector3(0,1.8,-900), Vector3(18,3.6,1.0), track_colors[track])

    # Start/finish gantry and repeated neon gates.
    for z in [42,-180,-420,-660]:
        _box(self, Vector3(0,4.2,z), Vector3(18,0.35,0.35), track_colors[track])
        _box(self, Vector3(-8.5,2.1,z), Vector3(0.35,4.2,0.35), track_colors[track])
        _box(self, Vector3(8.5,2.1,z), Vector3(0.35,4.2,0.35), track_colors[track])

func _start_race():
    state = "race"
    _clear_world()
    _build_environment(selected_track)
    finish_z = -900.0
    car = _make_car(car_colors[selected_car], Vector3(0,0.65,55))
    var lanes = [-5.0,-1.7,1.7,5.0]
    var ai_colors = [Color(1,0.12,0.15),Color(1,0.55,0.05),Color(0.7,0.12,1),Color(0.1,0.9,0.65)]
    for i in 4:
        var opp = _make_car(ai_colors[i], Vector3(lanes[i],0.65,35+i*9), 0.95)
        opponents.append({"node":opp,"speed":19.0+float(i)*1.8})
    camera = Camera3D.new()
    add_child(camera)
    camera.position = Vector3(0,6.2,70)
    camera.current = true
    countdown = 3.0
    race_time = 0.0
    speed = 0.0
    nitro = 100.0
    finished = false
    _show_race_hud()

func _setup_ui():
    ui = CanvasLayer.new()
    add_child(ui)
    _show_menu()

func _clear_ui():
    for c in ui.get_children():
        c.queue_free()
    menu_box = null
    race_hud = null
    result_panel = null

func _button(text: String) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(340,58)
    b.add_theme_font_size_override("font_size",22)
    return b

func _show_menu():
    _clear_ui()
    var root := CenterContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(520,560)
    root.add_child(panel)
    menu_box = VBoxContainer.new()
    menu_box.add_theme_constant_override("separation",12)
    panel.add_child(menu_box)
    var title := Label.new()
    title.text = "RUSHX"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",64)
    menu_box.add_child(title)
    var sub := Label.new()
    sub.text = "3D STREET RACING"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size",20)
    menu_box.add_child(sub)
    var race := _button("QUICK RACE")
    race.pressed.connect(_start_race)
    menu_box.add_child(race)
    var track := _button("TRACKS  •  " + track_names[selected_track])
    track.pressed.connect(_cycle_track)
    menu_box.add_child(track)
    var garage := _button("GARAGE  •  CAR " + str(selected_car+1))
    garage.pressed.connect(_cycle_car)
    menu_box.add_child(garage)
    var modes := Label.new()
    modes.text = "CAREER  •  DRIFT  •  DRAG  •  TIME TRIAL  •  POLICE\nMore modes unlock as the RUSHX career expands."
    modes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    modes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    modes.add_theme_font_size_override("font_size",15)
    menu_box.add_child(modes)
    info_label = Label.new()
    info_label.text = "Choose a track and car, then race."
    info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    menu_box.add_child(info_label)

func _cycle_track():
    selected_track = (selected_track + 1) % track_names.size()
    _show_menu()

func _cycle_car():
    selected_car = (selected_car + 1) % car_colors.size()
    _show_menu()

func _show_race_hud():
    _clear_ui()
    var hud := Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(hud)
    race_hud = hud
    var top := Label.new()
    top.position = Vector2(28,22)
    top.text = "RUSHX  •  " + track_names[selected_track]
    top.add_theme_font_size_override("font_size",26)
    hud.add_child(top)
    speed_label = Label.new()
    speed_label.position = Vector2(28,62)
    speed_label.add_theme_font_size_override("font_size",20)
    hud.add_child(speed_label)
    nitro_label = Label.new()
    nitro_label.position = Vector2(1000,28)
    nitro_label.add_theme_font_size_override("font_size",20)
    hud.add_child(nitro_label)
    race_label = Label.new()
    race_label.position = Vector2(1000,65)
    race_label.add_theme_font_size_override("font_size",17)
    hud.add_child(race_label)
    countdown_label = Label.new()
    countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    countdown_label.add_theme_font_size_override("font_size",72)
    hud.add_child(countdown_label)
    var hint := Label.new()
    hint.position = Vector2(28,680)
    hint.text = "◀ / A   STEER     ↓ / BRAKE     SPACE / CENTER   NITRO"
    hint.add_theme_font_size_override("font_size",15)
    hud.add_child(hint)

func _show_results():
    _clear_ui()
    var root := CenterContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)
    result_panel = PanelContainer.new()
    result_panel.custom_minimum_size = Vector2(520,390)
    root.add_child(result_panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation",14)
    result_panel.add_child(box)
    var h := Label.new()
    h.text = "RACE COMPLETE"
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size",38)
    box.add_child(h)
    var d := Label.new()
    d.text = track_names[selected_track] + "\nTIME  %.2f SEC\nREWARD  +250 COINS  •  +500 XP" % race_time
    d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    d.add_theme_font_size_override("font_size",20)
    box.add_child(d)
    var again := _button("RACE AGAIN")
    again.pressed.connect(_start_race)
    box.add_child(again)
    var menu := _button("MAIN MENU")
    menu.pressed.connect(_show_menu)
    box.add_child(menu)

func _physics_process(delta):
    if state != "race" or car == null:
        return
    if countdown > 0:
        countdown -= delta
        countdown_label.text = str(int(ceil(countdown)))
        if countdown <= 0:
            countdown_label.text = "GO!"
        return
    if countdown_label.text != "":
        countdown_label.text = ""
    race_time += delta
    var steer := Input.get_axis("ui_left","ui_right")
    var braking := Input.is_action_pressed("ui_down")
    var boost := Input.is_action_pressed("ui_accept") and nitro > 0.0
    var target := 30.0
    if braking: target = 9.0
    if boost:
        target = 52.0
        nitro = max(0.0,nitro-34.0*delta)
    else:
        nitro = min(100.0,nitro+10.0*delta)
    speed = lerp(speed,target,4.0*delta)
    car.velocity = Vector3(steer*11.0,0,-speed)
    car.move_and_slide()
    car.position.x = clamp(car.position.x,-7.0,7.0)
    for data in opponents:
        var opp: CharacterBody3D = data["node"]
        opp.position.z -= float(data["speed"])*delta
        if opp.position.z < finish_z-30:
            opp.position.z = 55
    camera.position = Vector3(car.position.x*0.35,6.0,car.position.z+15.0)
    camera.look_at(Vector3(car.position.x,0.4,car.position.z-28),Vector3.UP)
    speed_label.text = "SPEED  %03d KM/H    TIME  %05.1f" % [int(speed*4.2),race_time]
    nitro_label.text = "NITRO  %03d%%" % int(nitro)
    race_label.text = "TRACK  %d/3    DISTANCE  %d M" % [selected_track+1,int(max(0.0,(car.position.z-finish_z)/3.0))]
    if car.position.z <= finish_z:
        finished = true
        state = "results"
        _show_results()

func _unhandled_input(event):
    if state != "race":
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            var w := get_viewport().get_visible_rect().size.x
            if event.position.x < w*0.35:
                Input.action_press("ui_left")
            elif event.position.x > w*0.65:
                Input.action_press("ui_right")
            else:
                Input.action_press("ui_accept")
        else:
            Input.action_release("ui_left")
            Input.action_release("ui_right")
            Input.action_release("ui_accept")
