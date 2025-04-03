import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/widgets.dart';

class GameButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  GameButton({
    required Vector2 position,
    required Vector2 size,
    required String imagePath,
    required this.onPressed,
    required this.onReleased,
  }) : super(position: position, size: size) {
    _imagePath = imagePath;
    anchor = Anchor.center;
  }

  late String _imagePath;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(_imagePath);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onReleased();
  }

  @override
  void onTapUp(TapUpEvent event) {
    onPressed();
  }
}
