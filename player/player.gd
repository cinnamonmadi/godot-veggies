extends KinematicBody2D

onready var liftoff_particle_scene = load("res://player/liftoff_particle.tscn")
onready var bullet_scene = load("res://player/bullet.tscn")

onready var sprite = $sprite
onready var jump_input_timer = $jump_input_timer
onready var coyote_timer = $coyote_timer
onready var shot_timer = $shot_timer
onready var invuln_timer = $invuln_timer

const SPEED = 100
const GRAVITY = 5
const MAX_FALL_SPEED = 150
const JUMP_IMPULSE = 150
const JUMP_INPUT_DURATION = 0.06
const COYOTE_TIME_DURATION = 0.06
const SHOT_DELAY = 0.06
const INVULN_DURATION = 0.16
const KNOCKBACK_SPEED = Vector2(150, -100)

var direction = 0
var grounded = false
var velocity = Vector2.ZERO
var knockback_enabled = false

func _ready():
    invuln_timer.connect("timeout", self, "_on_invuln_timeout")

    var shader = load("res://shader/whitemask.shader").duplicate(true)
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = shader

func handle_input():
    if Input.is_action_just_pressed("player_left"):
        direction = -1
    if Input.is_action_just_pressed("player_right"):
        direction = 1
    if Input.is_action_just_released("player_left"):
        if Input.is_action_pressed("player_right"):
            direction = 1
        else:
            direction = 0
    if Input.is_action_just_released("player_right"):
        if Input.is_action_pressed("player_left"):
            direction = -1
        else:
            direction = 0
    if Input.is_action_just_pressed("player_jump"):
        jump_input_timer.start(JUMP_INPUT_DURATION)
    if Input.is_action_just_pressed("player_shoot"):
        shoot()

func _physics_process(_delta):
    handle_input()
    move()
    if get_slide_count():
        knockback_enabled = false
    update_sprite()

func move():
    if invuln_timer.is_stopped() and direction != 0:
        knockback_enabled = false

    if not knockback_enabled:
        velocity.x = direction * SPEED
    velocity.y += GRAVITY
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

    var was_grounded = grounded
    grounded = is_on_floor()
    if was_grounded and not grounded:
        coyote_timer.start(COYOTE_TIME_DURATION)
    if (grounded or not coyote_timer.is_stopped()) and not jump_input_timer.is_stopped():
        jump_input_timer.stop()
        jump()
    if grounded and velocity.y >= 5:
        velocity.y = 5
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

    move_and_slide(velocity, Vector2(0, -1))

func jump():
    self.velocity.y = -JUMP_IMPULSE
    grounded = false
    var liftoff_particle = liftoff_particle_scene.instance()
    liftoff_particle.position = position
    get_parent().add_child(liftoff_particle)

func shoot():
    if not shot_timer.is_stopped():
        return

    var bullet = bullet_scene.instance()
    var bullet_direction = 1
    if sprite.flip_h:
        bullet_direction = -1
    bullet.init(position + Vector2(bullet_direction * 15, 0), bullet_direction)
    get_parent().add_child(bullet)

    shot_timer.start(SHOT_DELAY)

func update_sprite():
    if grounded and direction == 0:
        sprite.play("idle")
    elif grounded and direction != 0:
        sprite.play("run")
    else:
        if abs(velocity.y) < 25:
            sprite.play("jump_peak")
        elif velocity.y < 0:
            sprite.play("jump")
        else:
            sprite.play("fall")
    if (direction == 1 and sprite.flip_h) or (direction == -1 and not sprite.flip_h):
        sprite.flip_h = not sprite.flip_h

func take_damage(source, amount):
    if not invuln_timer.is_stopped():
        return

    velocity = KNOCKBACK_SPEED
    if source.x >= position.x:
        velocity.x *= -1
    knockback_enabled = true
    sprite.material.set_shader_param("whitemask_enabled", true)
    invuln_timer.start(INVULN_DURATION)

func _on_invuln_timeout():
    sprite.material.set_shader_param("whitemask_enabled", false)
