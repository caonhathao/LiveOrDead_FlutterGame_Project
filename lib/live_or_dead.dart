import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'dart:async';
import 'package:flame/flame.dart';
import 'package:live_or_dead/components/controller.dart';
import 'package:live_or_dead/components/enemy.dart';
import 'dart:developer' as dev;
import 'package:live_or_dead/levels/level.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/input.dart';
import 'package:live_or_dead/components/player.dart';

class LiveOrDead extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        TapCallbacks,
        HasCollisionDetection {
  @override
  Color backgroundColor() => const Color.fromARGB(255, 59, 59, 59);
  LiveOrDead()
      : super(
            camera: CameraComponent.withFixedResolution(
                width: 32 * 44, height: 32 * 20));
  Player player = Player(
    uriCharacter: 'Characters/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets',
  );
  Enemy enemy = Enemy(uriEnemy: 'Enemy/NightBorne/80x80_PNGSheets');

  late JoystickComponent joystick;
  bool isEndGame = false;

  Future<void> reloadAllImages() async {
    Flame.images.clearCache();
  }

  @override
  Future<void> onLoad() async {
    dev.log('Initializing game...');

    //Load all images into cache
    await images.loadAllImages();

    camera.viewfinder
      ..zoom = 1.0
      ..anchor = Anchor.topLeft
      ..position = Vector2(0, 0);

    camera.viewport =
        FixedResolutionViewport(resolution: Vector2(32 * 44, 32 * 20));
    camera.viewport.priority = 0;

    world = Level(
      levelName: 'Map_02',
      player: player,
      enemy: enemy,
    );

    await Future.wait([
      Future.value(add(camera)),
      Future.value(add(world)),
    ]);

    addJoystick();
    addActionButton();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    updateJoystick();
    enemy.playerPosition = player.position;
    //do someting here if player death - stop game
    super.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final Vector2 worldTouchPos =
        camera.viewport.globalToLocal(event.localPosition);
    if (worldTouchPos.x <= 400) joystick.position = worldTouchPos;
    // log('worldTouchPos: $worldTouchPos');
    // log('localTouchPos: ${event.localPosition.toString()}');
  }

  @override
  void onTapUp(TapUpEvent event) {
    joystick.position = Vector2(140, 500);
  }

  @override
  void onMount() {
    super.onMount();
    dev.log("Level has been mounted to the world!");
  }

  Future<void> addJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: EdgeInsets.only(left: 40, bottom: 40),
      anchor: Anchor.center,
    );

    joystick.priority = 100;
    camera.viewport.add(joystick);
    // log('default joystick position: $joystick.position');
  }

  Future<void> addActionButton() async {
    final atkButton = GameButton(
        position: Vector2(40 * 32, 15 * 32),
        size: Vector2(120, 120),
        imagePath: 'HUD/AtkButton.png',
        onPressed: () {
          player.isAttack = true;
        },
        onReleased: () {
          player.isFight = true;
        });
    camera.viewport.add(atkButton);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
      case JoystickDirection.left:
        player.horizonalMovement = -1;
        break;
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
      case JoystickDirection.right:
        player.horizonalMovement = 1;
        break;
      case JoystickDirection.up:
        player.hasJumped = true;
        break;
      default:
        player.horizonalMovement = 0;
        break;
    }
  }
}
