extends KinematicBody2D

onready var death_particle_scene = load("res://enemies/cherry/cherry_death_particle.tscn")
onready var cherry_bomb_scene = load("res://enemies/cherry/cherry_bomb.tscn")

onready var sprite = $sprite
onready var invuln_timer = $invuln_timer
onready var player = get_parent().get_node("player")

const GRAVITY = 5
const MAX_FALL_SPEED = 150
const INVULN_DURATION = 0.08
const MAX_HEALTH = 10
const SEARCH_RADIUS = 200

var direction = 1
var grounded = false
var velocity = Vector2.ZERO
var attacking = false
var health = MAX_HEALTH
var has_projectile = false

func _ready():
    add_to_group("enemies")
    sprite.connect("animation_finished", self, "_on_animation_finished")
    invuln_timer.connect("timeout", self, "_on_invuln_timeout")

    var shader = load("res://shader/whitemask.shader").duplicate(true)
    sprite.material = ShaderMaterial.new()
    sprite.material.shader = shader

func _physics_process(_delta):
    move_apply_gravity()
    move_and_slide(velocity, Vector2(0, -1))

    if not attacking and position.distance_to(player.position) <= SEARCH_RADIUS:
        if player.position.x > position.x:
            direction = 1
        else:
            direction = -1
        has_projectile = true
        attacking = true
    elif attacking and has_projectile and sprite.frame == 4:
        fire_projectile()
        has_projectile = false

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

func fire_projectile():
    var cherry_bomb = cherry_bomb_scene.instance()
    var spawn_offset = Vector2(7, -15)
    if direction == -1:
        spawn_offset.x = -9
    cherry_bomb.init(position + spawn_offset, player.position)
    get_parent().add_child(cherry_bomb)

func update_sprite():
    if attacking:
        sprite.play("attack")
    else:
        sprite.play("idle")
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
