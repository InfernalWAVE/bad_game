extends Spatial

const CAM_V_MAX = 75
const CAM_V_MIN = -55

var camera_rot_h: float = 0.0
var camera_rot_v: float = 0.0
var player_mesh_front
var rotation_speed

export var h_sensitivity: float = 0.1
export var v_sensitivity: float = 0.1
export var h_acceleration: float = 10
export var v_acceleration: float = 10
export var rotation_speed_multiplier: float = 0.15

onready var player = get_parent()
onready var player_mesh = get_node("../Body")
onready var h_controller = $HorizontalController
onready var v_controller = $HorizontalController/VerticalController
onready var camera = $HorizontalController/VerticalController/Eyes/ClippedCamera
onready var mouse_delay = $mouse_control_start_delay


func _ready():
	camera.add_exception(player)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if Input.is_action_just_pressed("toggle_mouse_capture"):
		if (Input.get_mouse_mode() == 2):
			Input.set_mouse_mode(0)
		else:
			Input.set_mouse_mode(2)
	
	if event is InputEventMouseMotion:
		mouse_delay.start()
		camera_rot_h += -event.relative.x * h_sensitivity
		camera_rot_v += event.relative.y * v_sensitivity

func _physics_process(delta):
	camera_rot_v = clamp(camera_rot_v,CAM_V_MIN,CAM_V_MAX)
	player_mesh_front = player_mesh.global_transform.basis.z
	rotation_speed = (PI - player_mesh_front.angle_to(h_controller.global_transform.basis.z)) * player.velocity.length() * rotation_speed_multiplier

	if mouse_delay.is_stopped():
		h_controller.rotation.y = lerp_angle(h_controller.rotation.y, player_mesh.global_transform.basis.get_euler().y, delta * rotation_speed_multiplier)
		camera_rot_h = h_controller.rotation_degrees.y
	else:
		h_controller.rotation_degrees.y = lerp(h_controller.rotation_degrees.y, camera_rot_h, delta * h_acceleration)
	
	v_controller.rotation_degrees.x = lerp(v_controller.rotation_degrees.x, camera_rot_v, delta * v_acceleration)
	
