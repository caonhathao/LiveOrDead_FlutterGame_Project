import 'dart:developer' as dev;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:live_or_dead/components/collision_block.dart';
import 'package:live_or_dead/components/enemy.dart';
import 'dart:async';
import 'package:live_or_dead/live_or_dead.dart';
import 'package:flutter/services.dart';
import 'package:live_or_dead/components/utils.dart/';

enum PlayerState { idle, running, attack, jumping, falling, death }

enum PlayerHitBox { idle, attack }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<LiveOrDead>, KeyboardHandler, CollisionCallbacks {
  Player({position, required this.uriCharacter})
      : super(priority: 10, position: position, size: Vector2(120, 80)) {
    debugMode = true;
  }
  String uriCharacter;
  late final SpriteAnimation idleAnim;
  late final SpriteAnimation runAnim;
  late final SpriteAnimation jumpAnim;
  late final SpriteAnimation fallAnim;
  late final SpriteAnimation attackAnim;
  late final SpriteAnimation deathAnim;
  late ShapeHitbox hitbox;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 300;
  final double _terminalVelocity = 300;
  final double attackCooldown = 0.7;
  int healthPoint = 120;
  int atkPoint = 5;
  double horizonalMovement = 0;
  double lastAttackTime = 0;
  double moveSpeed = 200;
  bool isTouchingLeft = false;
  bool isTouchingRight = false;
  bool isAttack = false;
  bool isFight =
      false; //when player finishes its atkAnim, make this flag is true and start minus point to enemy
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
    //dev.log('Player healthPointPoint: $healthPoint');
    if (healthPoint > 0) {
      _updatePlayerState();
      _updatePlayerMovement(dt);
      _applyGravity(dt);
      lastAttackTime += dt;
    } else {
      //dev.log('Player is death');
      current = PlayerState.death;
      gameRef.isEndGame = true;
    }
    super.update(dt);
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

    if (other is Enemy) {
      if (other.healthPoint > 0) {
        if (isFight) {
          other.healthPoint -= atkPoint;
          isFight = false;
          
          dev.log('Enemy health point: ${other.healthPoint}');
        }
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is CollisionBlock) {
      //dev.log('Player get out of collision');
      isTouchingLeft = false;
      isTouchingRight = false;
    }
  }

  Future<void> _loadAllAnimations() async {
    idleAnim =
        animationSpriteSheet(gameRef, '_Idle', uriCharacter, Vector2(120, 80))
            .createAnimation(row: 0, stepTime: stepTime, to: 9, from: 0);
    runAnim =
        animationSpriteSheet(gameRef, '_Run', uriCharacter, Vector2(120, 80))
            .createAnimation(row: 0, stepTime: stepTime, to: 9, from: 0);
    jumpAnim =
        animationSpriteSheet(gameRef, '_Jump', uriCharacter, Vector2(120, 80))
            .createAnimation(row: 0, stepTime: stepTime, to: 1, from: 0);
    fallAnim = animationSpriteSheet(
            gameRef, '_JumpFallInbetween', uriCharacter, Vector2(120, 80))
        .createAnimation(row: 0, stepTime: stepTime, to: 2, from: 0);
    attackAnim = animationSpriteSheet(
            gameRef, '_AttackComboNoMovement', uriCharacter, Vector2(120, 80))
        .createAnimation(
            row: 0, stepTime: stepTime, to: 9, from: 0, loop: false);
    deathAnim =
        animationSpriteSheet(gameRef, '_Death', uriCharacter, Vector2(120, 80))
            .createAnimation(
                row: 0, stepTime: stepTime, to: 9, from: 0, loop: false);

    //List fo all animations
    animations = {
      PlayerState.idle: idleAnim,
      PlayerState.running: runAnim,
      PlayerState.jumping: jumpAnim,
      PlayerState.falling: fallAnim,
      PlayerState.attack: attackAnim,
      PlayerState.death: deathAnim,
    };

    dev.log('Animations loaded successfully!');
    return super.onLoad();
  }

  // @override
  // void onMount() {
  //   super.onMount();
  //   dev.log('The position of the player is: $position');
  //   dev.log('The size of the player is: $size');
  // }

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
    //is Player is jumpping, keep state jumped
    if (velocity.x > 0 || velocity.x < 0) {
      if (hasJumped && isOnGround == false) {
        state = PlayerState.jumping;
      } else {
        state = PlayerState.running;
      }
    }

    if (isAttack) {
      state = PlayerState.attack;
      hitBox = hitBoxes[PlayerHitBox.attack] ?? Vector2.zero();

      animationTicker?.onComplete = () {
        state = PlayerState.idle;
        isAttack = false;
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
