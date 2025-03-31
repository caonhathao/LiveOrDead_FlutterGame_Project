import 'dart:developer' as dev;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:live_or_dead/components/collision_block.dart';
import 'dart:async';
import 'package:live_or_dead/live_or_dead.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

enum PlayerState { idle, running, attack, jumping, falling }

enum PlayerHitBox { idle, attack }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<LiveOrDead>, KeyboardHandler, CollisionCallbacks {
  Player({position, required this.uriCharacter})
      : super(priority: 10, position: position, size: Vector2(120, 80));
  String uriCharacter;
  late final SpriteAnimation idleAnim;
  late final SpriteAnimation runAnim;
  late final SpriteAnimation jumpAnim;
  late final SpriteAnimation fallAnim;
  late final SpriteAnimation attackAnim;
  late ShapeHitbox hitbox;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 300;
  final double _terminalVelocity = 300;
  double horizonalMovement = 0;
  double moveSpeed = 100;
  bool isTouchingLeft = false;
  bool isTouchingRight = false;
  bool isAttached = false;
  bool isOnGround = false;
  bool hasJumped = false;
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  final Vector2 fromAbove = Vector2(0, -1); // Upward direction

  static final Map<PlayerHitBox, Vector2> hitBoxes = {
    PlayerHitBox.idle: Vector2(35, 80),
    PlayerHitBox.attack: Vector2(70, 80)
  };
  late Vector2 hitBox;

  @override
  Future<void> onLoad() async {
    await _loadAllAnimations();
    current = PlayerState.idle;
    hitBox = hitBoxes[PlayerHitBox.idle] ?? Vector2.zero();
    hitbox = RectangleHitbox(size: hitBox, position: Vector2(40, 0))
      ..debugMode = true
      ..debugColor = Color.fromARGB(235, 189, 0, 0);

    await add(hitbox);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updatePlayerState();
    _updatePlayerMovement(dt);
    _applyGravity(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizonalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizonalMovement += isLeftKeyPressed ? -1 : 0;
    horizonalMovement += isRightKeyPressed ? 1 : 0;
    return true; // Indicate that the key event was handled
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CollisionBlock) {
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
              2;
      final collisionNormal = absoluteCenter - mid;
      final separateDistance = (size.x / 2) - collisionNormal.length;
      collisionNormal.normalize();

      if (fromAbove.dot(collisionNormal) > 0.9) {
        isOnGround = true;
        velocity.y = 0;
      }
      // position += collisionNormal.scaled(separateDistance);
      position.y = other.position.y - size.y;
    }

    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is CollisionBlock) {
      dev.log('get out of collision');
      isTouchingLeft = false;
      isTouchingRight = false;
    }
  }

  Future<void> _loadAllAnimations() async {
    idleAnim = _animationSpriteSheet('_Idle')
        .createAnimation(row: 0, stepTime: stepTime, to: 9, from: 0);
    runAnim = _animationSpriteSheet('_Run')
        .createAnimation(row: 0, stepTime: stepTime, to: 9, from: 0);
    jumpAnim = _animationSpriteSheet('_Jump')
        .createAnimation(row: 0, stepTime: stepTime, to: 1, from: 0);
    fallAnim = _animationSpriteSheet('_JumpFallInbetween')
        .createAnimation(row: 0, stepTime: stepTime, to: 2, from: 0);
    attackAnim = _animationSpriteSheet('_AttackComboNoMovement')
        .createAnimation(
            row: 0, stepTime: stepTime, to: 9, from: 0, loop: false);

    //List fo all animations
    animations = {
      PlayerState.idle: idleAnim,
      PlayerState.running: runAnim,
      PlayerState.jumping: jumpAnim,
      PlayerState.falling: fallAnim,
      PlayerState.attack: attackAnim,
    };

    dev.log('Animations loaded successfully!');
    return super.onLoad();
  }

  SpriteSheet _animationSpriteSheet(String nameAnimation) {
    return SpriteSheet(
      image: gameRef.images.fromCache('$uriCharacter/$nameAnimation.png'),
      srcSize: Vector2(120, 80),
    );
  }

  @override
  void onMount() {
    super.onMount();
    dev.log('The position of the player is: $position');
    dev.log('The size of the player is: $size');
  }

  void _updatePlayerMovement(double dt) {
    velocity.x = horizonalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  Future<void> _updatePlayerState() async {
    PlayerState state = PlayerState.idle;
    hitBox = hitBoxes[PlayerHitBox.idle] ?? Vector2.zero();

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (isTouchingLeft || isTouchingRight) {
      state = PlayerState.idle;
    }
    //Check if moving,set running state
    if (velocity.x > 0 || velocity.x < 0) {
      state = PlayerState.running;
    }

    if (isAttached) {
      state = PlayerState.attack;
      hitBox = hitBoxes[PlayerHitBox.attack] ?? Vector2.zero();

      animationTicker?.onComplete = () {
        state = PlayerState.idle;
        isAttached = false;
      };
    }
    remove(hitbox);
    hitbox = RectangleHitbox(size: hitBox, position: Vector2(40, 0))
      ..debugMode = true
      ..debugColor = Color.fromARGB(235, 189, 0, 0);

    await add(hitbox);
    current = state;
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    if (hasJumped) {
      if (isOnGround) {
        velocity.y = -_jumpForce;
        isOnGround = false;
      }
      hasJumped = false;
    }
    position.y += velocity.y * dt;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
  }
}
