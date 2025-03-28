import 'dart:developer' as dev;
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'dart:async';
import 'dart:ui';
import 'package:live_or_dead/live_or_dead.dart';

enum PlayerState { idle, running, jumping, falling }

class Test extends SpriteAnimationGroupComponent with HasGameRef<LiveOrDead> {
  Test() : super(priority: 0);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  final double stepTime = 0.05;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    size = Vector2(1200, 80);
    checkLoaded();
    return super.onLoad();
  }

  Future<void> _loadAllAnimations() async {
    await gameRef.images.load(
        'Characters/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png');
    final background = SpriteComponent(
        sprite: await Sprite.load(
            'Characters/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png'),
        size: Vector2(1200, 80));

        await add(background);

    final spriteSheet = SpriteSheet(
        image: await gameRef.images.load(
            'Characters/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png'),
        srcSize: Vector2(120, 80));

    idleAnimation =
        spriteSheet.createAnimation(row: 0, stepTime: 0.1, to: 9, from: 0);
    dev.log('Animations loaded successfully!');
  }

  void checkLoaded() {
    dev.log(
        'Loaded files: ${gameRef.images.fromCache('Characters/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png').size}');
  }

  @override
  void onMount() {
    super.onMount();
    dev.log('The position of the player is: $position');
    dev.log('The size of the player is: $size');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = const Color(0xFFFF00FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(toRect(), paint);
  }
}
