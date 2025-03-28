import 'dart:developer' as dev;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:live_or_dead/components/collision_block.dart';
import 'dart:async';
import 'package:live_or_dead/live_or_dead.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

enum PlayerState { idle, running, jumping, falling }

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<LiveOrDead>, KeyboardHandler, CollisionCallbacks {
  Player({position, required this.uriCharacter})
      : super(priority: 10, position: position, size: Vector2(120, 80));
  String uriCharacter;
  late final SpriteAnimation idleAnim;
  late final SpriteAnimation runAnim;
  late final SpriteAnimation jumpAnim;
  late final SpriteAnimation fallAnim;
  final double stepTime = 0.05;

  final double _gravity = 9.8;
  final double _jumpForce = 300;
  final double _terminalVelocity = 300;
  double horizonalMovement = 0;
  double moveSpeed = 100;
  bool isTouchingLeft = false;
  bool isTouchingRight = false;
  bool isOnGround = false;
  bool hasJumped = false;
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  final Vector2 fromAbove = Vector2(0, -1); // Upward direction

  @override
  Future<void> onLoad() async {
    await _loadAllAnimations();
    current = PlayerState.idle;
    await add(RectangleHitbox(size: Vector2(35, 80), position: Vector2(40, 0))
      ..debugMode = true
      ..debugColor = Color.fromARGB(235, 189, 0, 0));
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
      position.y = other.position.y-size.y;
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

    //List fo all animations
    animations = {
      PlayerState.idle: idleAnim,
      PlayerState.running: runAnim,
      PlayerState.jumping: jumpAnim,
      PlayerState.falling: fallAnim,
    };

    dev.log('Animations loaded successfully!');
    return super.onLoad();
  }

  // void checkLoaded() {
  //   dev.log(
  //       'Loaded files: ${gameRef.images.fromCache('Characters/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png')}');
  // }

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

  void _updatePlayerState() {
    PlayerState state = PlayerState.idle;
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
