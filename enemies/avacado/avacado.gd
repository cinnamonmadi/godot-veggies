extends KinematicBody2D

onready var toast_particle_scene = load("res://enemies/avacado/avacado_toast_particle.tscn")

onready var sprite = $sprite
onready var walk_hitbox = $walk_hitbox
onready var charge_left_hitbox = $charge_left_hitbox
onready var charge_right_hitbox = $charge_right_hitbox
onready var hurtbox = $hurtbox
onready var invuln_timer = $invuln_timer
onready var player = get_parent().get_node("player")

enum { STATE_WALKING, STATE_STANDING, STATE_CHARGING, STATE_FLOPPING }

const WALK_SPEED = 25
const CHARGE_SPEED = 100
const GRAVITY = 5
const MAX_FALL_SPEED = 150
const INVULN_DURATION = 0.08
const MAX_HEALTH = 10
const SEARCH_RADIUS = 200

var direction = -1
var grounded = false
var velocity = Vector2.ZERO
var state = STATE_WALKING
var health = MAX_HEALTH

func _ready():
    add_to_group("enemies")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    invuln_timer.connect("timeout", self, "_on_invuln_timeout")

    var shader = load("res://shader/whitemask.shader").duplicate(true)
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = shader

func _physics_process(_delta):
    if state == STATE_WALKING:
        move_apply_gravity()
        velocity.x = direction * WALK_SPEED
        var linear_velocity = move_and_slide(velocity, Vector2(0, -1))
        if linear_velocity.x == 0:
            direction *= -1
        if position.distance_to(player.position) <= SEARCH_RADIUS:
            var facing_player = (player.position.x < position.x and direction == -1) or (player.position.x > position.x and direction == 1)
            if facing_player:
                state = STATE_STANDING
    elif state == STATE_STANDING:
        if sprite.frame == 3:
            walk_hitbox.disabled = true
            if direction == -1:
                charge_left_hitbox.disabled = false
            elif direction == 1:
                charge_right_hitbox.disabled = false
    elif state == STATE_CHARGING:
        move_apply_gravity()
        velocity.x = direction * CHARGE_SPEED
        var linear_velocity = move_and_slide(velocity, Vector2(0, -1))
        if linear_velocity.x == 0:
            state = STATE_FLOPPING
    elif state == STATE_FLOPPING:
        if sprite.frame == 2:
            walk_hitbox.disabled = false
            charge_left_hitbox.disabled = true
            charge_right_hitbox.disabled = true
            if hurtbox.overlaps_body(player):
                player.take_damage(position, 1)

    update_sprite()

func move_apply_gravity():
    velocity.y += GRAVITY
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

    grounded = is_on_floor()
    if grounded and velocity.y >= 5:
        velocity.y = 5
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

func update_sprite():
    if state == STATE_WALKING:
        sprite.play("walk")
    elif state == STATE_STANDING:
        sprite.play("stand")
    elif state == STATE_CHARGING:
        sprite.play("charge")
    elif state == STATE_FLOPPING:
        sprite.play("flop")
    if (direction == -1 and sprite.flip_h) or (direction == 1 and not sprite.flip_h):
        sprite.flip_h = not sprite.flip_h

func take_damage(source_direction, amount):
    if not invuln_timer.is_stopped():
        return

    if not walk_hitbox.disabled:
        return

    if source_direction == direction:
        return

    health -= amount
    sprite.material.set_shader_param("whitemask_enabled", true)
    invuln_timer.start(INVULN_DURATION)

    if health <= 0:
        var toast_particle = toast_particle_scene.instance()
        toast_particle.position = position
        toast_particle.flip_h = sprite.flip_h
        get_parent().add_child(toast_particle)

        queue_free()

func _on_animation_finished():
    if state == STATE_STANDING:
        state = STATE_CHARGING
        sprite.play("charge")
    elif state == STATE_FLOPPING:
        state = STATE_WALKING
        sprite.play("walk")

func _on_invuln_timeout():
    sprite.material.set_shader_param("whitemask_enabled", false)
