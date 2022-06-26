extends KinematicBody

const MIN_CAMERA_ANGLE = -60
const MAX_CAMERA_ANGLE = 70
const GRAVITY = -20
const AIM_TURN_FACTOR = 0.015

export var angular_acceleration: float = 7
export var acceleration: float = 6.0
export var walk_jump: float = 12.0
export var sprint_jump: float = 30
export var walk_speed: float = 10.0
export var sprint_speed: float = 50.0
export var jump_impulse: float = 12.0
export var roll_magnitude: float = 17.0

onready var camera = $Camera
onready var h_controller = $Camera/HorizontalController
onready var body = $Body

var velocity: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.BACK
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var speed: float = 0.0
var aim_turn: float = 0.0

func _ready():
	direction = Vector3.BACK.rotated(Vector3.UP, h_controller.global_transform.basis.get_euler().y)

func _input(event):
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * AIM_TURN_FACTOR
	if Input.is_action_just_pressed("dance"):
		if $Anim.current_animation != "dance":
			$Anim.play("dance")
		else:
			$Anim.play("idle")
			
	if (Input.is_action_pressed("left") || Input.is_action_pressed("right") || Input.is_action_pressed("forward") || Input.is_action_pressed("backward")):
		$input_timer.start()
		
#	if event is InputEventKey:
#		if (event.as_text() == "W" || event.as_text() == "A" || event.as_text() == "S" || event.as_text() == "D" || event.as_text() == "Space"):
#			if event.pressed:
#				print(event.as_text())
#			else:
#				print("")

func _physics_process(delta):
	if Input.is_action_pressed("aim"):
		$AnimationTree.set("parameters/aim_transition/current", 0)
	else:
		$AnimationTree.set("parameters/aim_transition/current", 1)
	
	var h_rot = h_controller.global_transform.basis.get_euler().y
	
	if (Input.is_action_pressed("left") || Input.is_action_pressed("right") || Input.is_action_pressed("forward") || Input.is_action_pressed("backward")):
		$input_timer.start()
		direction = Vector3(Input.get_action_strength("left") - Input.get_action_strength("right"),
							0,
							Input.get_action_strength("forward") - Input.get_action_strength("backward"))
							
		strafe_dir = direction
		direction = direction.rotated(Vector3.UP,h_rot).normalized()
		
		
		if Input.is_action_pressed("sprint"):
			speed = sprint_speed
			jump_impulse = sprint_jump
		else:
			speed = walk_speed
			jump_impulse = walk_jump
		if is_on_floor() && $Anim.current_animation != "dance":
			$Anim.play("run")
	else:
		if $Anim.current_animation == "falling_idle" && is_on_floor():
			$Anim.play("idle")
		speed = 0.0
		strafe_dir = Vector3.ZERO
		
	if Input.is_action_just_pressed("jump"):
		if $Anim.current_animation != "dance":
			$Anim.play("jump")
		
		velocity.y = jump_impulse
	
	if $AnimationTree.get("parameters/aim_transition/current") == 1:
		$Body.rotation.y = lerp_angle($Body.rotation.y, atan2(direction.x, direction.z) - rotation.y, delta * angular_acceleration)
		# Sometimes in the level design you might need to rotate the Player object itself
		# - rotation.y in case you need to rotate the Player object
	else:
		$Body.rotation.y = lerp_angle($Body.rotation.y, h_controller.rotation.y, delta * angular_acceleration)
		# lerping towards $Camroot/h.rotation.y while aiming, h_rot(as in the video) doesn't work if you rotate Player object
	
	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	
	aim_turn = 0.0

	velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity,Vector3.UP)
	
	body.rotation.y = lerp_angle(body.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)
	
	if ($input_timer.is_stopped() && $Anim.current_animation != "dance"):
		$Anim.play("idle")


func _on_Anim_animation_finished(anim_name):
	if (anim_name == "jump"):
		$Anim.play("falling_idle")
	if (anim_name == "run"):
		$Anim.play("idle")
	if (anim_name == "dance"):
		$Anim.play("idle")
	if (anim_name == "falling_idle"):
		$Anim.play("idle")
