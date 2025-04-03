import 'package:flame/components.dart';

class HealthBar extends SpriteComponent {
  final double maxHealth;
  double currentHealth;

  HealthBar({required this.maxHealth, required this.currentHealth,required Vector2 position}) : super(position: position) {
    debugMode = true;
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Others/HeartBar/_HP_00.png'); // Ảnh thanh máu đầy
  }

  void updateHealth(double newHealth) async {
    currentHealth = newHealth;

    if (currentHealth >= maxHealth * 0.9) {
      sprite = await Sprite.load('Others/HeartBar/_HP_00.png');
    } else if (currentHealth >= maxHealth * 0.8) {
      sprite = await Sprite.load('Others/HeartBar/_HP_01.png');
    } else if (currentHealth >= maxHealth * 0.7) {
      sprite = await Sprite.load('Others/HeartBar/_HP_02.png');
    } else if (currentHealth >= maxHealth * 0.6) {
      sprite = await Sprite.load('Others/HeartBar/_HP_03.png');
    } else if (currentHealth >= maxHealth * 0.5) {
      sprite = await Sprite.load('Others/HeartBar/_HP_04.png');
    } else if (currentHealth >= maxHealth * 0.4) {
      sprite = await Sprite.load('Others/HeartBar/_HP_05.png');
    } else if (currentHealth >= maxHealth * 0.3) {
      sprite = await Sprite.load('Others/HeartBar/_HP_06.png');
    } else if (currentHealth >= maxHealth * 0.2) {
      sprite = await Sprite.load('Others/HeartBar/_HP_07.png');
    } else if (currentHealth >= maxHealth * 0.1) {
      sprite = await Sprite.load('Others/HeartBar/_HP_08.png');
    } else if (currentHealth >= maxHealth * 0.0) {
      sprite = await Sprite.load('Others/HeartBar/_HP_09.png');
    }
  }
}
