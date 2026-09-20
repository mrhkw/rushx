extends Node3D

const SAVE_PATH="user://rushx_save.json"
const LEVELS=100
var ui:CanvasLayer
var player:CharacterBody3D
var cam:Camera3D
var state="menu"
var level=1
var car_id=0
var speed=0.0
var nitro=100.0
var timer=0.0
var countdown=3.0
var paused=false
var world_nodes:Array[Node]=[]
var ai:Array[Dictionary]=[]
var traffic:Array[Dictionary]=[]
var route:Array[Vector3]=[]
var checkpoints:Array[Vector3]=[]
var checkpoint=0
var damage=0.0
var stars:Dictionary={}
var upgrades:Dictionary={}
var owned:Array=[0]
var money=2500
var xp=0
var wins=0
var races=0
var total_distance=0.0
var best_speed=0.0
var achievements:Array=[]
var settings={"graphics":2,"controls":0,"sensitivity":1.0,"music":true,"sound":true,"vibration":true,"fps_debug":false,"auto_quality":true,"resolution":"FULL HD"}
var lap=1
var max_laps=1
var objective=""
var camera_mode=0
var rng=RandomNumberGenerator.new()

var worlds=["BEGINNER CITY","HIGHWAY","DESERT","MOUNTAIN","FOREST","COASTAL","INDUSTRIAL","NIGHT CITY","EXTREME ROADS","ULTIMATE CHAMPIONSHIP"]
var world_colors=[Color("#28b7ff"),Color("#ff9b42"),Color("#d7b35b"),Color("#8caeff"),Color("#5bcf7e"),Color("#31d6d0"),Color("#a176ff"),Color("#e55cff"),Color("#ff5757"),Color("#ffd44a")]
var types=["Normal Race","Circuit Race","Sprint Race","Time Trial","Checkpoint Race","Elimination Race","Overtake Challenge","Traffic Challenge","Drift Challenge","Speed Challenge","Nitro Challenge","Rival Race","Boss Race","Escape Challenge","Survival Race","Delivery Race","Precision Driving","Highway Chase","Multi-lap Race","Final Championship"]
var names=["City Start","First Chase","Downtown Rush","Traffic Run","Sunset Sprint","Bridge Attack","Night Shortcut","Highway Entry","Fast Lane","City Champion","Express Arrival","Lane Runner","Bridge Lights","Road Warriors","Tunnel Flash","Overpass Run","Highway Heat","Service Station","Long Haul","Highway Boss","Sandline","Dune Runner","Canyon Cut","Dust Trail","Oasis Dash","Red Rock Rush","Desert Heat","Mirage Route","Storm Front","Desert Boss","Summit Entry","Hairpin Hunter","Cliffside","Peak Pursuit","Tunnel Drop","Alpine Rush","Rockslide Run","High Pass","Mountain Storm","Summit Boss","Greenway","Forest Sprint","Pine Shadow","Muddy Mile","Wooden Bridge","Wild Trail","Fog Woods","Ranger Route","Deep Forest","Forest Boss","Coastal Entry","Sea Breeze","Cliff Drive","Harbor Run","Beachline","Island Cut","Ocean Storm","Lighthouse Dash","Wave Runner","Coast Boss","Factory Start","Container Rush","Crane Alley","Freight Lane","Warehouse Run","Steel Sprint","Night Shift","Dock Escape","Heavy Haul","Industrial Boss","Neon Arrival","Midnight Run","Rain Lights","Cyber Boulevard","Neon Tunnel","Electric Drift","City Afterdark","Wet Asphalt","Skyline Chase","Night Boss","Extreme Entry","Canyon Edge","Broken Road","Storm Pass","Dead Drop","Razor Ridge","Last Shortcut","Inferno Highway","Final Gauntlet","Extreme Boss","Championship Heat","Worlds Collide","Ultimate Sprint","Four Corners","Final Duel","Grand Circuit","Victory Road","Crown Chase","Last Lap","Ultimate Championship"]
var cars=[
{"n":"RUSH 01","s":180.0,"a":7.5,"h":8.2,"b":7.4,"g":7.8,"d":7.0,"c":Color("#28a9ff")},
{"n":"VOLT GT","s":194.0,"a":8.1,"h":8.0,"b":7.7,"g":8.0,"d":6.7,"c":Color("#ff334d")},
{"n":"NOVA R","s":205.0,"a":8.6,"h":7.7,"b":8.0,"g":7.6,"d":7.2,"c":Color("#a55cff")},
{"n":"BLAZE V8","s":211.0,"a":9.1,"h":7.1,"b":7.5,"g":7.2,"d":8.0,"c":Color("#ff9d32")},
{"n":"AERO S","s":218.0,"a":8.7,"h":8.5,"b":8.2,"g":8.4,"d":7.5,"c":Color("#32e6a2")},
{"n":"PHANTOM","s":224.0,"a":9.0,"h":8.6,"b":8.5,"g":8.5,"d":7.8,"c":Color("#5c76ff")},
{"n":"RAPTOR X","s":231.0,"a":9.3,"h":8.2,"b":8.8,"g":8.0,"d":8.4,"c":Color("#ff5a3d")},
{"n":"ECLIPSE","s":238.0,"a":9.5,"h":8.8,"b":9.0,"g":8.7,"d":8.0,"c":Color("#d45cff")},
{"n":"STORM GT","s":244.0,"a":9.7,"h":8.5,"b":9.2,"g":8.4,"d":8.6,"c":Color("#39d7ff")},
{"n":"TITAN RS","s":249.0,"a":9.9,"h":8.0,"b":9.0,"g":8.1,"d":9.0,"c":Color("#ffd23c")},
{"n":"VORTEX","s":254.0,"a":10.0,"h":9.0,"b":9.3,"g":8.9,"d":8.8,"c":Color("#ff4e86")},
{"n":"APEX 11","s":260.0,"a":10.2,"h":9.2,"b":9.5,"g":9.1,"d":9.0,"c":Color("#48ff8d")},
{"n":"ZENITH","s":266.0,"a":10.4,"h":9.4,"b":9.6,"g":9.3,"d":9.1,"c":Color("#7a9dff")},
{"n":"INFERNO","s":272.0,"a":10.7,"h":9.0,"b":9.7,"g":8.9,"d":9.5,"c":Color("#ff5b2e")},
{"n":"RUSHX ONE","s":285.0,"a":11.0,"h":9.7,"b":10.0,"g":9.8,"d":9.8,"c":Color("#f4f4f4")}]

func _ready():
	rng.randomize()
	inputs()
	show_loading("Starting RUSHX…",10)
	call_deferred("_boot_game")

func _boot_game():
	await get_tree().process_frame
	load_game()
	apply_graphics_settings()
	menu()

func show_loading(message:String, progress:float=0.0):
	if ui==null:
		ui=CanvasLayer.new()
		add_child(ui)
	for x in ui.get_children(): x.queue_free()
	var bg:=ColorRect.new()
	bg.color=Color("#05070d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var boxc:=VBoxContainer.new()
	boxc.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	boxc.custom_minimum_size=Vector2(520,150)
	boxc.position=Vector2(-260,-75)
	boxc.add_theme_constant_override("separation",12)
	ui.add_child(boxc)
	var title:Label=label("RUSHX",52)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boxc.add_child(title)
	var msg:Label=label(message,20)
	msg.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	boxc.add_child(msg)
	var bar:=ProgressBar.new()
	bar.custom_minimum_size=Vector2(520,18)
	bar.value=progress
	bar.show_percentage=false
	boxc.add_child(bar)

func inputs():
	for x in [["accel",KEY_W],["accel",KEY_UP],["brake",KEY_S],["brake",KEY_DOWN],["left",KEY_A],["left",KEY_LEFT],["right",KEY_D],["right",KEY_RIGHT],["hand",KEY_SPACE],["nitro",KEY_SHIFT],["camera",KEY_C],["pause",KEY_ESCAPE],["restart",KEY_R]]:
		if not InputMap.has_action(x[0]): InputMap.add_action(x[0])
		var e:=InputEventKey.new();e.physical_keycode=x[1];InputMap.action_add_event(x[0],e)

func mat(c:Color,em:=Color.TRANSPARENT):
	var m:=StandardMaterial3D.new();m.albedo_color=c;m.metallic=.25;m.roughness=.42
	if em.a>0:m.emission_enabled=true;m.emission=em;m.emission_energy_multiplier=2
	return m

func box(p:Node,pos:Vector3,size:Vector3,c:Color,em:=Color.TRANSPARENT):
	var n:=MeshInstance3D.new();var b:=BoxMesh.new();b.size=size;n.mesh=b;n.position=pos;n.material_override=mat(c,em);p.add_child(n);world_nodes.append(n);return n

func cyl(p:Node,pos:Vector3,r:float,h:float,c:Color,rot:=Vector3.ZERO):
	var n:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=r;m.bottom_radius=r;m.height=h;n.mesh=m;n.position=pos;n.rotation=rot;n.material_override=mat(c);p.add_child(n);world_nodes.append(n);return n

func label(t:String,size:int=20):
	var l:=Label.new();l.text=t;l.add_theme_font_size_override("font_size",size);return l

func button(t:String,w:=320.0):
	var b:=Button.new();b.text=t;b.custom_minimum_size=Vector2(w,52);b.add_theme_font_size_override("font_size",18);return b

func clear_ui():
	if ui==null:ui=CanvasLayer.new();add_child(ui)
	for n in ui.get_children():n.queue_free()

func data(id:int)->Dictionary:
	var w=int((id-1)/10);var local=int((id-1)%10)+1;var typ=types[((id-1)*7+local)%types.size()]
	if local==10:typ="Boss Race"
	if id==100:typ="Final Championship"
	var weather=["Sunny","Cloudy","Rain","Heavy Rain","Fog","Storm"][(id*3+local)%6]
	var time=["Morning","Noon","Afternoon","Sunset","Night"][(id+w)%5]
	return {"id":id,"w":w,"local":local,"name":names[id-1],"type":typ,"weather":weather,"time":time,"length":850+local*95+w*70,"opp":3+min(6,int(w/2)),"reward":300+id*85,"xp":150+id*45,"target":70+id*1.1,"laps":3 if id==100 else (2 if typ in ["Circuit Race","Multi-lap Race","Final Championship"] else 1),"objective":objective_for(id,typ)}

func objective_for(id:int,typ:String)->String:
	if id==100:return "Complete the Ultimate Championship"
	match typ:
		"Time Trial": return "Beat the target time"
		"Drift Challenge": return "Finish with a clean drift run"
		"Overtake Challenge": return "Finish while overtaking traffic"
		"Speed Challenge": return "Reach the required top speed"
		"Nitro Challenge": return "Use Nitro strategically and finish"
		"Boss Race": return "Defeat the world boss"
	return "Reach the finish and beat the opponents"

func update_fps(dt):
	if not settings.get("fps_debug",false): return
	if ui and ui.has_meta("fps"):
		ui.get_meta("fps").text="FPS %.0f | Objects %d"%[Engine.get_frames_per_second(),get_tree().get_node_count()]

func menu():
	state="menu";clear_ui()
	var bg:=ColorRect.new();bg.color=Color("#060912");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(bg)
	var v:=VBoxContainer.new();v.anchor_left=.5;v.anchor_right=.5;v.offset_left=-290;v.offset_right=290;v.offset_top=35;v.add_theme_constant_override("separation",7);ui.add_child(v)
	var t=label("RUSHX",72);t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(t)
	var s=label("FULL HD 3D • 100 LEVEL RACING",18);s.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(s)
	for q in [["PLAY / CAREER",Callable(self,"world_map")],["WORLD MAP",Callable(self,"world_map")],["GARAGE",Callable(self,"garage")],["CARS",Callable(self,"cars_menu")],["UPGRADES",Callable(self,"upgrades_menu")],["PROFILE",Callable(self,"profile")],["ACHIEVEMENTS",Callable(self,"achievements_menu")],["SETTINGS",Callable(self,"settings_menu")]]:
		var b=button(q[0]);b.pressed.connect(q[1]);v.add_child(b)
	v.add_child(label("XP %d • MONEY $%d • STARS %d/300"%[xp,money,total_stars()],16))

func total_stars()->int:
	var n=0
	for k in stars:n+=int(stars[k])
	return n

func unlocked(id:int)->bool:
	if id==1:return true
	return int(stars.get(str(id-1),0))>0 and total_stars()>=data(id).w*5

func world_map():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(15,12);v.anchor_right=1;v.offset_right=-30;ui.add_child(v);v.add_child(label("WORLD MAP • 100 LEVELS",30))
	var g:=GridContainer.new();g.columns=10;g.size_flags_vertical=Control.SIZE_EXPAND_FILL;v.add_child(g)
	for i in range(1,101):
		var d=data(i);var b=button("%02d\n%s\n★%d"%[i,d.name.left(10),int(stars.get(str(i),0))],125);b.disabled=not unlocked(i)
		if not b.disabled:b.pressed.connect(func(n=i):level=n;start_race())
		g.add_child(b)
	var back=button("BACK");back.pressed.connect(menu);v.add_child(back)

func garage():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(25,25);ui.add_child(v);v.add_child(label("GARAGE • 15 CARS",38))
	v.add_child(label("%s\nSpeed %.0f • Accel %.1f • Handling %.1f\nBrake %.1f • Grip %.1f • Drift %.1f"%[cars[car_id].n,cars[car_id].s,cars[car_id].a,cars[car_id].h,cars[car_id].b,cars[car_id].g,cars[car_id].d],22))
	var b=button("NEXT CAR");b.pressed.connect(func():car_id=(car_id+1)%15;garage());v.add_child(b)
	b=button("UPGRADE PARTS");b.pressed.connect(upgrades_menu);v.add_child(b);b=button("BACK");b.pressed.connect(menu);v.add_child(b)

func _select_car(n:int):
	car_id=n
	if not owned.has(n):owned.append(n)
	save_game()
	garage()

func cars_menu():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(20,15);ui.add_child(v);v.add_child(label("CARS • 15 UNIQUE",34))
	for i in range(15):
		var ok=i==0 or total_stars()>=i*4;var b=button("%02d %s • %.0f KM/H • %s"%[i+1,cars[i].n,cars[i].s,"UNLOCKED" if ok else "LOCKED"],650);b.disabled=not ok
		if ok:b.pressed.connect(func():_select_car(i))
		v.add_child(b)
	var back=button("BACK");back.pressed.connect(menu);v.add_child(back)

func upgrades_menu():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(25,15);ui.add_child(v);v.add_child(label("UPGRADES • "+cars[car_id].n,34))
	for p in ["engine","turbo","transmission","brakes","tires","suspension","weight","nitro","aero"]:
		var k=str(car_id)+":"+p;var lv=int(upgrades.get(k,0));var cost=250+lv*300;var b=button("%s • LEVEL %d/5 • $%d"%[p.to_upper(),lv,cost],520);b.disabled=lv>=5 or money<cost;b.pressed.connect(func(part=p,c=cost):buy_upgrade(part,c));v.add_child(b)
	var back=button("BACK");back.pressed.connect(garage);v.add_child(back)

func buy_upgrade(p,c):
	var k=str(car_id)+":"+p;var lv=int(upgrades.get(k,0))
	if lv<5 and money>=c:money-=c;upgrades[k]=lv+1;save_game()
	upgrades_menu()

func profile():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(30,25);ui.add_child(v);v.add_child(label("PROFILE",40));v.add_child(label("LEVEL %d\nXP %d\nMONEY $%d\nCARS %d/15\nRACES %d\nWINS %d\nDISTANCE %.1f KM\nBEST SPEED %.0f KM/H\nSTARS %d/300"%[1+int(xp/5000),xp,money,owned.size(),races,wins,total_distance/1000,best_speed,total_stars()],20));var b=button("BACK");b.pressed.connect(menu);v.add_child(b)

func achievements_menu():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(30,20);ui.add_child(v);v.add_child(label("ACHIEVEMENTS",36))
	for a in ["First Win","Speed Demon","Drift Master","10 Wins","50 Wins","100 Levels","Perfect Race","Nitro Expert","No Crash","Champion"]:
		var b=button(("✓ " if achievements.has(a) else "○ ")+a,480);b.disabled=true;v.add_child(b)
	var back=button("BACK");back.pressed.connect(menu);v.add_child(back)

func settings_menu():
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(30,20);ui.add_child(v);v.add_child(label("SETTINGS",36))
	var b=button("GRAPHICS: "+["LOW","MEDIUM","HIGH","ULTRA"][settings.graphics]);b.pressed.connect(func():settings.graphics=(settings.graphics+1)%4;save_game();settings_menu());v.add_child(b)
	b=button("CONTROLS: "+["BUTTON","TILT","TOUCH"][settings.controls]);b.pressed.connect(func():settings.controls=(settings.controls+1)%3;save_game();settings_menu());v.add_child(b)
	b=button("SENSITIVITY: %.1f"%settings.sensitivity);b.pressed.connect(func():settings.sensitivity=.6 if settings.sensitivity>1.3 else settings.sensitivity+.2;save_game();settings_menu());v.add_child(b)
	b=button("MUSIC: "+("ON" if settings.music else "OFF"));b.pressed.connect(func():settings.music=not settings.music;save_game();settings_menu());v.add_child(b)
	b=button("SOUND: "+("ON" if settings.sound else "OFF"));b.pressed.connect(func():settings.sound=not settings.sound;save_game();settings_menu());v.add_child(b)
	b=button("VIBRATION: "+("ON" if settings.vibration else "OFF"));b.pressed.connect(func():settings.vibration=not settings.vibration;save_game();settings_menu());v.add_child(b)
	b=button("AUTO QUALITY: "+("ON" if settings.auto_quality else "OFF"));b.pressed.connect(func():settings.auto_quality=not settings.auto_quality;save_game();settings_menu());v.add_child(b)
	b=button("FPS DEBUG: "+("ON" if settings.fps_debug else "OFF"));b.pressed.connect(func():settings.fps_debug=not settings.fps_debug;save_game();settings_menu());v.add_child(b)
	b=button("BACK");b.pressed.connect(menu);v.add_child(b)

func car(id:int,pos:Vector3,small:=false):
	var n:=CharacterBody3D.new();n.position=pos;add_child(n);world_nodes.append(n);var c:Color=cars[id].c
	box(n,Vector3(0,.55,0),Vector3(2,.62,4),c);box(n,Vector3(0,.95,.15),Vector3(1.45,.5,1.7),c.darkened(.16));box(n,Vector3(0,1.05,-.05),Vector3(1.2,.22,1.3),Color("#172b3b"))
	for x in [-.86,.86]:
		for z in [-1.28,1.28]:cyl(n,Vector3(x,.29,z),.3,.2,Color("#101116"),Vector3(0,0,PI/2))
	box(n,Vector3(0,.48,-2.01),Vector3(1.5,.15,.1),Color("#dcecff"),Color("#dcecff"));box(n,Vector3(0,.48,2.01),Vector3(1.5,.15,.1),Color("#ff263d"),Color("#ff263d"))
	var cs:=CollisionShape3D.new();var sh:=BoxShape3D.new();sh.size=Vector3(1.85,.9,3.8);cs.shape=sh;cs.position.y=.55;n.add_child(cs);if small:n.scale*=.82
	return n

func build_world(d):
	var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=world_colors[d.w].darkened(.78);e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=world_colors[d.w];e.ambient_light_energy=.9
	if d.weather in ["Fog","Storm"]:
		e.fog_enabled=true
		e.fog_light_color=world_colors[d.w]
		e.fog_density=.008 if d.weather=="Fog" else .004
	if d.time=="Night": e.ambient_light_energy=.38
	env.environment=e;add_child(env);world_nodes.append(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-35,0);sun.light_energy=.6 if d.time=="Night" else 1.2;sun.shadow_enabled=settings.graphics>=1;add_child(sun);world_nodes.append(sun)
	var segments=int(d.length/22);route.clear()
	for i in range(segments+1):
		var z=55-i*22;var x=sin((i+d.id)*.52)*(3+d.w%4)+sin(i*.19)*2
		if d.local in [3,6,9]:x+=sin(i*.9)*2
		route.append(Vector3(x,0,z))
	for i in range(segments):
		var a=route[i];var b=route[i+1];var mid=(a+b)/2;var ln=a.distance_to(b)+3;var r=box(self,mid+Vector3(0,-.28,0),Vector3(18,.55,ln),Color("#252832"));r.look_at(Vector3(b.x,mid.y,b.z),Vector3.UP)
		for lane in [-6,-2,2,6]:
			var m=box(self,mid+Vector3(lane,.02,0),Vector3(.16,.06,ln*.82),Color("#d7d9df"));m.look_at(Vector3(b.x,mid.y,b.z),Vector3.UP)
		box(self,mid+Vector3(-9.5,0,0),Vector3(.4,.7,ln),world_colors[d.w],world_colors[d.w]);box(self,mid+Vector3(9.5,0,0),Vector3(.4,.7,ln),world_colors[d.w],world_colors[d.w])
		detail(d,mid,i)
	var c=6+d.local%4;checkpoints.clear()
	for j in range(c):
		var p=route[clamp(int((j+1)*float(segments)/float(c+1)),1,segments)];checkpoints.append(p);box(self,p+Vector3(0,3.5,0),Vector3(18,.35,.35),world_colors[d.w],world_colors[d.w])
	var finish=route.back();box(self,finish+Vector3(0,4.4,0),Vector3(18,.4,.5),Color.WHITE,Color.WHITE)

func detail(d,pos,i):
	var side=-1 if i%2==0 else 1;var p=pos+Vector3(side*(13+(i%3)*3),0,0)
	match d.w:
		0,7:
			box(self,p+Vector3(0,3,0),Vector3(8,6,12),Color("#252a44"));box(self,p+Vector3(0,7,0),Vector3(7,.3,3),world_colors[d.w],world_colors[d.w])
		1:
			cyl(self,p+Vector3(0,3,0),2,6,Color("#496c34"))
		2:
			cyl(self,p+Vector3(0,1.4,0),1.2,2.8,Color("#8c6844"));cyl(self,p+Vector3(0,3.5,0),2.3,2.0,Color("#d19a50"))
		3,8: box(self,p+Vector3(0,3,0),Vector3(7,6,8),Color("#68707d"))
		4:
			cyl(self,p+Vector3(0,2.2,0),.65,4.4,Color("#5d4937"));cyl(self,p+Vector3(0,5,0),2.4,2,Color("#356b43"))
		5: box(self,p+Vector3(0,1,0),Vector3(8,2,5),Color("#e1d0a0"))
		6: box(self,p+Vector3(0,3,0),Vector3(8,6,10),Color("#555761"))
		9: box(self,p+Vector3(0,4,0),Vector3(10,8,10),Color("#5a5d66"))

func start_race():
	if state=="loading":
		return
	state="loading"
	paused=false
	show_loading("Loading Level %d…" % level,20)
	await get_tree().process_frame
	var d=data(level)
	_clear_world()
	show_loading("Building %s…" % d.name,55)
	await get_tree().process_frame
	build_world(d)
	await get_tree().process_frame
	if route.is_empty():
		show_load_error("Track generation failed. The game was protected from a black screen.")
		return
	player=car(car_id,route[0]+Vector3(0,.7,10))
	cam=Camera3D.new()
	add_child(cam)
	cam.current=true
	spawn_ai(d)
	spawn_traffic(d)
	show_loading("Preparing physics, AI and traffic…",82)
	await get_tree().process_frame
	state="race"
	countdown=3.0
	timer=0.0
	lap=1
	max_laps=int(d.laps)
	objective=d.objective
	checkpoint=0
	speed=0.0
	nitro=100.0
	damage=0.0
	checkpoint=0
	render_environment_quality()
	show_loading("Race ready!",100)
	await get_tree().create_timer(0.12).timeout
	race_ui(d)

func _clear_world():
	for n in world_nodes:
		if is_instance_valid(n):
			n.free()
	world_nodes.clear()
	ai.clear()
	traffic.clear()
	route.clear()
	checkpoints.clear()
	player=null
	cam=null

func show_load_error(message:String):
	state="error"
	clear_ui()
	var v:=VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.position=Vector2(-260,-90)
	v.custom_minimum_size=Vector2(520,180)
	v.add_theme_constant_override("separation",10)
	ui.add_child(v)
	var title:Label=label("GAME LOAD ERROR",32)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var msg:Label=label(message,18)
	msg.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	v.add_child(msg)
	var retry:Button=button("RETRY")
	retry.pressed.connect(start_race)
	v.add_child(retry)
	var back:Button=button("MAIN MENU")
	back.pressed.connect(menu)
	v.add_child(back)

func apply_graphics_settings():
	var quality=int(settings.get("graphics",2))
	var scale=[0.70,0.82,0.94,1.0][clamp(quality,0,3)]
	get_viewport().scaling_3d_scale=scale

func render_environment_quality():
	var quality=int(settings.get("graphics",2))
	var shadow=quality>=1
	for n in world_nodes:
		if n is DirectionalLight3D:
			n.shadow_enabled=shadow

func spawn_ai(d):
	ai.clear()
	for i in range(d.opp):
		var n=car((car_id+i+level)%15,route[0]+Vector3([-6,-2,2,6][i%4],.7,18+i*8));ai.append({"n":n,"speed":24+i*1.5+level*.08,"progress":0.0})

func spawn_traffic(d):
	traffic.clear()
	for i in range(int(8+d.w*2+d.local/3)):
		var n=car((i+d.w)%15,Vector3([-6,-2,2,6][i%4],.7,-40-i*65),true);traffic.append({"n":n,"speed":15+(i%5)*2.0,"lane":[-6,-2,2,6][i%4],"phase":i})

func race_ui(d):
	clear_ui();var h:=Control.new();h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(h)
	var a=label("WORLD %d • LEVEL %d\n%s" % [d.w+1,d.id,d.name],20);a.position=Vector2(20,15);h.add_child(a)
	var s=label("SPEED 000 KM/H\nRPM 0",22);s.position=Vector2(20,75);h.add_child(s);ui.set_meta("speed",s)
	var n=label("NITRO 100%",20);n.position=Vector2(1030,20);h.add_child(n);ui.set_meta("nitro",n)
	var o=label("POSITION 1/%d\n%s\n%s • %s\nOBJECTIVE: %s" % [d.opp+1,d.type,d.weather,d.time,d.objective],18);o.position=Vector2(900,70);o.custom_minimum_size=Vector2(360,130);h.add_child(o);ui.set_meta("obj",o)
	var cp=label("CHECKPOINT 0/%d\nLAP 1/%d" % [checkpoints.size(),max_laps],18);cp.position=Vector2(20,150);h.add_child(cp);ui.set_meta("cp",cp)
	var fps=label("",14);fps.position=Vector2(20,185);h.add_child(fps);ui.set_meta("fps",fps);fps.visible=settings.get("fps_debug",false)
	var c=label("",72);c.set_anchors_and_offsets_preset(Control.PRESET_CENTER);c.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;h.add_child(c);ui.set_meta("count",c)
	var pause=button("Ⅱ",55);pause.position=Vector2(1180,15);pause.pressed.connect(pause_game);h.add_child(pause)
	var l=button("◀",90);l.position=Vector2(20,620);l.button_down.connect(func():Input.action_press("left"));l.button_up.connect(func():Input.action_release("left"));h.add_child(l)
	var r=button("▶",90);r.position=Vector2(120,620);r.button_down.connect(func():Input.action_press("right"));r.button_up.connect(func():Input.action_release("right"));h.add_child(r)
	for q in [["BRAKE","brake"],["DRIFT","hand"],["NITRO","nitro"]]:
		var b=button(q[0],100);b.position=Vector2(900+(q[0]=="NITRO")*100,620);b.button_down.connect(func(x=q[1]):Input.action_press(x));b.button_up.connect(func(x=q[1]):Input.action_release(x));h.add_child(b)
	var acc=button("ACCEL",110);acc.position=Vector2(220,550);acc.button_down.connect(func():Input.action_press("accel"));acc.button_up.connect(func():Input.action_release("accel"));h.add_child(acc)

func pause_game():
	if state!="race":return
	paused=not paused
	if paused:
		clear_ui();var v:=VBoxContainer.new();v.position=Vector2(400,180);ui.add_child(v);v.add_child(label("PAUSED",44))
		for q in [["RESUME",Callable(self,"resume_race")],["RESTART",Callable(self,"start_race")],["SETTINGS",Callable(self,"settings_menu")],["QUIT RACE",Callable(self,"world_map")]]:
			var b=button(q[0]);b.pressed.connect(q[1]);v.add_child(b)
	else:race_ui(data(level))

func resume_race():
	paused=false
	race_ui(data(level))

func _physics_process(dt):
	if state!="race" or player==null or paused:return
	if countdown>0:
		countdown-=dt;get_node_or_null("/root/RUSHX")
		var c=ui.get_meta("count");c.text="GO!" if countdown<.6 else str(int(ceil(countdown)));return
	timer+=dt
	if Input.is_action_just_pressed("pause"):pause_game();return
	if Input.is_action_just_pressed("restart"):start_race();return
	if Input.is_action_just_pressed("camera"):camera_mode=(camera_mode+1)%5
	var steer=Input.get_axis("left","right");var accel=Input.is_action_pressed("accel");var brake=Input.is_action_pressed("brake");var hand=Input.is_action_pressed("hand");var boost=Input.is_action_pressed("nitro") and nitro>0
	var maxs=float(cars[car_id].s)/4.0;var up=int(upgrades.get(str(car_id)+":engine",0));maxs*=1+up*.025
	if accel:speed=move_toward(speed,maxs,(float(cars[car_id].a)+up*.25)*2.4*dt)
	else:speed=move_toward(speed,maxs*.18,3.5*dt)
	if brake:speed=move_toward(speed,-maxs*.25,9*dt)
	if boost:speed=move_toward(speed,maxs*1.28,18*dt);nitro=max(0,nitro-26*dt)
	else:nitro=min(100,nitro+8*dt)
	var turn=float(cars[car_id].h)/8.0
	if hand:turn*=.62
	player.rotation.y-=steer*turn*dt*(.7+speed/60.0);player.velocity=Vector3.FORWARD.rotated(Vector3.UP,player.rotation.y)*speed;player.move_and_slide();player.position.y=.72
	var near=nearest(player.position);player.position.x=lerp(player.position.x,near.x,.12*dt*10)
	total_distance+=abs(speed)*dt;best_speed=max(best_speed,abs(speed)*4)
	var d=data(level)
	update_ai(dt);update_traffic(dt);update_camera(dt);update_hud(d,boost);update_fps(dt)
	if checkpoint<checkpoints.size() and player.position.distance_to(checkpoints[checkpoint])<14:
		checkpoint+=1
		if checkpoint>=checkpoints.size() and lap<max_laps:
			lap+=1
			checkpoint=0
	if player.position.distance_to(route.back())<10 and checkpoint>=checkpoints.size():finish_race(d)

func nearest(p):
	var best=route[0];var bd=INF
	for q in route:
		var x=Vector2(p.x,p.z).distance_squared_to(Vector2(q.x,q.z))
		if x<bd:bd=x;best=q
	return best

func update_ai(dt):
	for q in ai:
		var n=q.n;n.position.z-=q.speed*dt;n.position.x=lerp(n.position.x,nearest(n.position).x,dt*1.8);q.progress=abs(n.position.z-route[0].z)
		if n.position.z<route.back().z:n.position.z=route[0].z+20

func update_traffic(dt):
	for q in traffic:
		var n=q.n;n.position.z-=q.speed*dt;n.position.x=q.lane+sin(Time.get_ticks_msec()/1000.0+q.phase)*.35
		if n.position.z<route.back().z-40:n.position.z=route[0].z-rng.randf_range(20,150);q.lane=[-6,-2,2,6][rng.randi_range(0,3)]
		if n.position.distance_to(player.position)<2.6:damage=min(100,damage+10*dt);speed*=.985

func update_camera(dt):
	var off=[Vector3(0,5.5,11.5),Vector3(0,3.5,8),Vector3(0,7.5,15),Vector3(0,1.6,2),Vector3(0,2.2,5)][camera_mode]
	cam.position=cam.position.lerp(player.position+off.rotated(Vector3.UP,player.rotation.y),dt*7);cam.look_at(player.position+Vector3(0,.7,0)-Vector3.FORWARD.rotated(Vector3.UP,player.rotation.y)*18,Vector3.UP)

func update_hud(d,boost):
	var s=ui.get_meta("speed");s.text="SPEED %03d KM/H\nRPM %d"%[int(abs(speed)*4),int(clamp(abs(speed)/max(1,float(cars[car_id].s)/4)*9000,800,9000))]
	ui.get_meta("nitro").text="NITRO %03d%% %s"%[int(nitro),"BOOST" if boost else ""]
	var pos=1
	for q in ai:
		if q.progress>abs(player.position.z-route[0].z):pos+=1
	ui.get_meta("obj").text="POSITION %d/%d\n%s\n%s • %s\nOBJECTIVE: %s\nTIME %.1f"%[pos,d.opp+1,d.type,d.weather,d.time,d.objective,timer]
	ui.get_meta("cp").text="CHECKPOINT %d/%d\nLAP %d/%d"%[checkpoint,checkpoints.size(),lap,max_laps]

func finish_race(d):
	state="results";var pos=1
	for q in ai:
		if q.progress>abs(player.position.z-route[0].z):pos+=1
	var st=1
	if pos==1:st=2
	if pos==1 and timer<=d.target:st=3
	var k=str(level);stars[k]=max(int(stars.get(k,0)),st);money+=d.reward+st*150;xp+=d.xp+st*75;races+=1
	if pos==1:wins+=1
	if not achievements.has("First Win") and wins>0:achievements.append("First Win")
	if wins>=10 and not achievements.has("10 Wins"):achievements.append("10 Wins")
	if wins>=50 and not achievements.has("50 Wins"):achievements.append("50 Wins")
	if level>=100 and not achievements.has("100 Levels"):achievements.append("100 Levels")
	if best_speed>=250 and not achievements.has("Speed Demon"):achievements.append("Speed Demon")
	if level==100 and not achievements.has("Champion"):achievements.append("Champion")
	if st==3 and not achievements.has("Perfect Race"):achievements.append("Perfect Race")
	if damage<=0.1 and not achievements.has("No Crash"):achievements.append("No Crash")
	if level==100 and not owned.has(14):owned.append(14)
	save_game();results(pos,st,d)

func results(pos,st,d):
	clear_ui();var v:=VBoxContainer.new();v.position=Vector2(350,110);ui.add_child(v);v.add_child(label("CHAMPIONSHIP COMPLETE" if level==100 else "RACE RESULTS",42));v.add_child(label("%s\nPOSITION %d/%d\nTIME %.2f\nSTARS %s\n+$%d\n+%d XP"%[d.name,pos,d.opp+1,timer,"★"*st,d.reward+st*150,d.xp+st*75],22))
	if level==100:v.add_child(label("FINAL TROPHY UNLOCKED • RUSHX ONE",22))
	var b=button("CONTINUE");b.pressed.connect(world_map);v.add_child(b);b=button("REPLAY");b.pressed.connect(start_race);v.add_child(b);b=button("GARAGE");b.pressed.connect(garage);v.add_child(b)

func save_game():
	var f=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"money":money,"xp":xp,"wins":wins,"races":races,"distance":total_distance,"best":best_speed,"owned":owned,"stars":stars,"upgrades":upgrades,"achievements":achievements,"car":car_id,"settings":settings}))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):return
	var f=FileAccess.open(SAVE_PATH,FileAccess.READ);var d=JSON.parse_string(f.get_as_text())
	if typeof(d)!=TYPE_DICTIONARY:return
	money=int(d.get("money",2500));xp=int(d.get("xp",0));wins=int(d.get("wins",0));races=int(d.get("races",0));total_distance=float(d.get("distance",0));best_speed=float(d.get("best",0));owned=d.get("owned",[0]);stars=d.get("stars",{});upgrades=d.get("upgrades",{});achievements=d.get("achievements",[]);car_id=int(d.get("car",0));settings=d.get("settings",settings)
