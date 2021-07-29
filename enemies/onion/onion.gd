extends KinematicBody2D

onready var death_particle_scene = load("res://enemies/onion/onion_death_particle.tscn")

onready var sprite = $sprite
onready var hurtbox = $hurtbox
onready var hurtbox_left = $hurtbox/left
onready var hurtbox_right = $hurtbox/right
onready var invuln_timer = $invuln_timer
onready var player = get_parent().get_node("player")

const SPEED = 50
const GRAVITY = 5
const MAX_FALL_SPEED = 150
const INVULN_DURATION = 0.08
const MAX_HEALTH = 10
const SEARCH_RADIUS = 200

var direction = 0
var grounded = false
var velocity = Vector2.ZERO
var attacking = false
var health = MAX_HEALTH

func _ready():
    add_to_group("enemies")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    invuln_timer.connect("timeout", self, "_on_invuln_timeout")

    var shader = load("res://shader/whitemask.shader").duplicate(true)
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = shader

func _physics_process(_delta):
    move()

    if not attacking and reached_player():
        attack_start()
    elif attacking:
        if hurtbox.overlaps_body(player) and sprite.frame == 5:
            player.take_damage(position, 1)

    update_sprite()

func move():
    if not attacking:
        move_chase_player()
    move_apply_gravity()
    move_and_slide(velocity, Vector2(0, -1))

func move_chase_player():
    if position.distance_to(player.position) <= SEARCH_RADIUS:
        if player.position.x > position.x:
            direction = 1
        else:
            direction = -1
    else:
        direction = 0
    velocity.x = direction * SPEED

func move_apply_gravity():
    velocity.y += GRAVITY
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

    grounded = is_on_floor()
    if grounded and velocity.y >= 5:
        velocity.y = 5
    if velocity.y > MAX_FALL_SPEED:
        velocity.y = MAX_FALL_SPEED

func reached_player():
    for i in get_slide_count():
        var collision = get_slide_collision(i)
        if collision.collider == player:
            return true

func attack_start():
    if direction == 1:
        hurtbox_left.disabled = true
        hurtbox_right.disabled = false
    elif direction == -1:
        hurtbox_left.disabled = false
        hurtbox_right.disabled = true
    velocity.x = 0
    attacking = true

func update_sprite():
    if attacking:
        sprite.play("attack")
    elif direction == 0:
        sprite.play("idle")
    else:
        sprite.play("run")
    if (direction == 1 and sprite.flip_h) or (direction == -1 and not sprite.flip_h):
        sprite.flip_h = not sprite.flip_h

func take_damage(_source, amount):
    if not invuln_timer.is_stopped():
        return

    health -= amount
    sprite.material.set_shader_param("whitemask_enabled", true)
    invuln_timer.start(INVULN_DURATION)

    if health <= 0:
        var death_particle = death_particle_scene.instance()
        death_particle.position = position
        death_particle.flip_h = sprite.flip_h
        get_parent().add_child(death_particle)

        queue_free()

func _on_animation_finished():
    if sprite.animation == "attack":
        attacking = false

func _on_invuln_timeout():
    sprite.material.set_shader_param("whitemask_enabled", false)
