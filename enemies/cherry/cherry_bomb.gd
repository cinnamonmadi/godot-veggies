extends Area2D

const SPEED = 120
const GRAVITY = 150
const ROTATION_SPEED = 5

var velocity = Vector2.ZERO
var direction = 1

func _ready():
    add_to_group("enemy_projectiles")

func init(start, target):
    position = start

    direction = 1
    if target.x < position.x:
        direction = -1
        $sprite.flip_h = true
        $sprite.offset.x *= -1

    velocity.x = SPEED * direction

    var t = (target.x - position.x) / velocity.x
    velocity.y = (target.y - position.y - (0.5 * GRAVITY * t * t)) / t

func take_damage(_source, _amount):
    queue_free()

func _physics_process(delta):
    velocity.y += GRAVITY * delta
    position += velocity * delta

    var collider_count = 0
    var colliders = get_overlapping_bodies()
    for collider in colliders:
        if collider.is_in_group("enemies"):
            continue
        collider_count += 1
        if collider.name == "player":
            collider.take_damage(position, 1)
            break

    rotation += direction * ROTATION_SPEED * delta

    if collider_count > 0:
        queue_free()
