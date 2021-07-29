extends Area2D

onready var sprite = $sprite
onready var life_timer = $life_timer

const TTL = 3
const SPEED = 350

var direction = 1

func _ready():
    life_timer.connect("timeout", self, "_on_life_timeout")
    life_timer.start(TTL)
    sprite.flip_h = direction == -1

func init(init_position, init_direction):
    position = init_position
    direction = init_direction

func _physics_process(delta):
    position += Vector2(direction * SPEED * delta, 0)

    var dealt_damage = false

    var colliders = get_overlapping_bodies()
    for collider in colliders:
        if collider.is_in_group("enemies"):
            collider.take_damage(direction, 1)
            dealt_damage = true
            break

    var collider_count = colliders.size()

    var area_colliders = get_overlapping_areas()
    if not dealt_damage:
        for collider in area_colliders:
            if collider.is_in_group("enemy_projectiles"):
                collider.take_damage(direction, 1)
                collider_count += 1
                break

    if collider_count > 0:
        queue_free()

func _on_life_timeout():
    queue_free()
