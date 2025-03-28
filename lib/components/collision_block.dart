import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'dart:ui';

class CollisionBlock extends PositionComponent with CollisionCallbacks {
  bool isPlatform = false;
  CollisionBlock({
    position,
    size,
    this.isPlatform = false,
  }) : super(position: position, size: size);
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()
      ..debugMode = true
      ..debugColor = Color.fromARGB(255, 0, 255, 0));
    return super.onLoad();
  }
}
