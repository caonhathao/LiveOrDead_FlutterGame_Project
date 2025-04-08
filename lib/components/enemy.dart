import 'dart:developer' as dev;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:live_or_dead/components/collision_block.dart';
import 'package:live_or_dead/components/player.dart';
import 'dart:async';
import 'package:live_or_dead/live_or_dead.dart';
import 'package:flutter/services.dart';
import 'package:live_or_dead/components/utils.dart';

enum EnemyState { idle, attack, running, die }

enum EnemyHitBox { idle, attack, running, die }

class Enemy extends SpriteAnimationGroupComponent
    with HasGameRef<LiveOrDead>, CollisionCallbacks {
  Enemy({position, required this.uriEnemy})
      : super(
          priority: 10,
          position: position,
          size: Vector2(40, 40),
        ) {
    debugMode = true;
  }

  String uriEnemy;
  Vector2? playerPosition;
  late final SpriteAnimation idleAnim;
  late final SpriteAnimation runAnim;
  late final SpriteAnimation attackAnim;
  late final SpriteAnimation dieAnim;
  late ShapeHitbox hitbox;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 300;
  final double _terminalVelocity = 300;
  final double attackCooldown = 1.0;
  int atkPoint = 10;
  int healthPoint = 50;
  int initialDirection = 0; //storing default direction
  double horizonalMovement = 0;
  double moveSpeed = 100;
  double lastAttackTime = 0;
  bool isTouchingLeft = false;
  bool isTouchingRight = false;
  bool isTouchingPlayer = false;
  bool isAttack = false;
  bool isOnGround = false;
  bool hasJumped = false;
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  final Vector2 fromAbove = Vector2(0, -1); // Upward direction
  static final Map<EnemyHitBox, Vector2> hitBoxSize = {
    EnemyHitBox.idle: Vector2(40, 40),
    EnemyHitBox.attack: Vector2(60, 40)
  };
  late Vector2 hitBox;

  @override
  Future<void> onLoad() async {
    await _loadAllAnimations();
    current = EnemyState.idle;
    hitBox = hitBoxSize[EnemyHitBox.idle] ?? Vector2.zero();
    hitbox = RectangleHitbox(size: hitBox, position: Vector2(0, 0))
      ..debugMode = true
      ..debugColor = Color.fromARGB(235, 189, 0, 0);

    await add(hitbox);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (healthPoint > 0) {
      _updateEnemyState();
      _updateEnemyMovement(dt);
      _applyGravity(dt);

      if (isAttack) {
        lastAttackTime += dt;
        //dev.log('LastAttackTime: $lastAttackTime');
      } else {
        lastAttackTime = 0;
      }
    } else if (healthPoint <= 0) {
      //dev.log('Enemy died');
      current = EnemyState.die;
      animationTicker?.onComplete = () {
        removeFromParent();
      };
    }
    super.update(dt);
  }

  @override
  Future<void> onCollision(
      Set<Vector2> intersectionPoints, PositionComponent other) async {
    if (other is CollisionBlock) {
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
              2;
      final collisionNormal = absoluteCenter - mid;
      // final separateDistance = (size.x / 2) - collisionNormal.length;
      collisionNormal.normalize();

      if (fromAbove.dot(collisionNormal) > 0.9) {
        isOnGround = true;
        velocity.y = 0;
      }
      // position += collisionNormal.scaled(separateDistance);
      position.y = other.position.y - size.y;
    }

    if (other is Player) {
      //dev.log('Enemy is touching player');
      if (healthPoint > 0) {
        horizonalMovement = 0;
        isTouchingPlayer = true;
        if (other.healthPoint > 0) {
          isAttack = true;
          //dev.log('Attacking');

          if (lastAttackTime.toInt() == attackCooldown.toInt()) {
            lastAttackTime = 0;
            other.healthPoint -= atkPoint;
            //dev.log('Player healthPoint: ${other.healthPoint}');
          }
        } else {
          isAttack = false;
        }
      }
    }

    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is CollisionBlock) {
      //dev.log('Enemy get out of collision');
      isTouchingLeft = false;
      isTouchingRight = false;
      //current = EnemyState.idle;
      isTouchingPlayer = false;
    }
    if (!isColliding) {
      // isAttack = false;
    }
    if(other is Player){
      isTouchingPlayer = false;
      isAttack = false;
    }
  }

  Future<void> _loadAllAnimations() async {
    idleAnim = animationSpriteSheet(gameRef, '_Idle', uriEnemy, Vector2(40, 40))
        .createAnimation(row: 0, stepTime: stepTime, to: 8, from: 0);
    runAnim = animationSpriteSheet(gameRef, '_Run', uriEnemy, Vector2(40, 40))
        .createAnimation(row: 0, stepTime: stepTime, to: 5, from: 0);
    attackAnim = animationSpriteSheet(
            gameRef, '_AttackComboNoMovement', uriEnemy, Vector2(60, 65))
        .createAnimation(
            row: 0, stepTime: stepTime, to: 11, from: 0, loop: true);
    dieAnim = animationSpriteSheet(gameRef, '_Death', uriEnemy, Vector2(80, 80))
        .createAnimation(
            row: 0, stepTime: stepTime, to: 22, from: 0, loop: false);

    //List fo all animations
    animations = {
      EnemyState.idle: idleAnim,
      EnemyState.running: runAnim,
      EnemyState.attack: attackAnim,
      EnemyState.die: dieAnim,
    };

    dev.log('Animations loaded successfully!');
    return super.onLoad();
  }

  Future<void> _updateEnemyState() async {
    EnemyState state = EnemyState.idle;
    hitBox = hitBoxSize[EnemyHitBox.idle] ?? Vector2.zero();

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (isTouchingLeft || isTouchingRight) {
      state = EnemyState.idle;
    }
    //Check if moving,set running state
    if (velocity.x > 0 || velocity.x < 0) {
      state = EnemyState.running;
    }

    if (isAttack) {
      state = EnemyState.attack;
      hitBox = hitBoxSize[EnemyHitBox.attack] ?? Vector2.zero();
      // dev.log('Attacking');
    }else{
          hitBox = hitBoxSize[EnemyHitBox.idle] ?? Vector2.zero();
      state = EnemyState.idle;
    }

    // remove(hitbox);
    // hitbox = RectangleHitbox(size: hitBox, position: Vector2(0, 0))
    //   ..debugMode = true
    //   ..debugColor = Color.fromARGB(235, 189, 0, 0);

    // await add(hitbox);

    hitbox.size = hitBox;
    hitbox.position = Vector2(0, 0);
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

  void _updateEnemyMovement(double dt) {
    if (isOnGround && isTouchingPlayer == false) {
      if (playerPosition != null) {
        //dev.log('player: ${playerPosition!.x} and enemy: ${position.x}');
        if (playerPosition!.x > position.x) {
          if (initialDirection == 0) {
            initialDirection = 1;
          }
          horizonalMovement = 1;
        } else if (playerPosition!.x < position.x) {
          if (initialDirection == 0) {
            initialDirection = -1;
          }
          //horizonalMovement = -1;


          if (initialDirection == 1 && playerPosition!.x >= position.x) {
            horizonalMovement = 1;
          } else if (initialDirection == -1 &&
              playerPosition!.x <= position.x) {
            horizonalMovement = -1;
          } else {
            horizonalMovement = (playerPosition!.x > position.x) ? 1 : -1;
            initialDirection = 0;
          }
        } else {
          horizonalMovement = 0;
        }
      } else {
        horizonalMovement = 0;
      }
    }
    if (isTouchingPlayer == false) {
      velocity.x = horizonalMovement * moveSpeed;
      position.x += velocity.x * dt;
    }
  }
}
