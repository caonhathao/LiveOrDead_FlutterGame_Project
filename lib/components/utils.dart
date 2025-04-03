import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:live_or_dead/live_or_dead.dart';

SpriteSheet animationSpriteSheet(
    LiveOrDead gameRef, String nameAnimation, String uri, Vector2 size) {
  return SpriteSheet(
    image: gameRef.images.fromCache('$uri/$nameAnimation.png'),
    srcSize: size,
  );
}
