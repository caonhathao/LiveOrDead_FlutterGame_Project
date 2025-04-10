import 'package:flame/components.dart';
import 'dart:async';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:live_or_dead/components/collision_block.dart';
import 'package:live_or_dead/components/enemy.dart';
import 'dart:developer';
import 'package:live_or_dead/components/player.dart';

class Level extends World {
  final String levelName;
  final Player player;
  // final Enemy enemy;
  final Enemy Function(Vector2 position) enemyFactory;
  List<Enemy> enemies = [];

  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];

  // Level({required this.levelName, required this.player, required this.enemy}) {
  //   priority = 1;
  // }

  Level({
    required this.levelName,
    required this.player,
    required this.enemyFactory,
  }) {
    priority = 1;
  }

  @override
  FutureOr<void> onLoad() async {
    try {
      level = await TiledComponent.load('$levelName.tmx', Vector2.all(32));
      log('Level loaded successfully!');
      // log("Map Size: ${level.size}");
      // log("Map position: ${level.position}");
    } catch (e) {
      log('Error loading file: $e');
    }
    await add(level);

    _loadCharacterLayer('Player', 'Player', (pos) => player);
    // _loadCharacterLayer('Enemy', 'Enemy', enemy);
    _loadCharacterLayer('Enemy', 'Enemy', (pos) {
      final e = enemyFactory(pos);
      enemies.add(e);
      return e;
    });

    final collisionsLayer =
        level.tileMap.getLayer<ObjectGroup>("GroundCollision");
    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'GroundCollision':
            final platform = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isPlatform: true,
            );
            collisionBlocks.add(platform);
            add(platform);
            break;
          default:
            break;
        }
      }
    } else {
      log('Can not find collision');
    }

    log('Level loaded!');
    player.collisionBlocks = collisionBlocks;
    return super.onLoad();
  }

  void _loadCharacterLayer(
    String nameLayer,
    String className,
    PositionComponent Function(Vector2 position) createComponent,
  ) {
    final layer = level.tileMap.getLayer<ObjectGroup>(nameLayer);
    if (layer != null) {
      //log(layer.objects.length.toString());
      for (final spawnPoint in layer.objects) {
        if (spawnPoint.class_ == className) {
          final position = Vector2(spawnPoint.x, spawnPoint.y);
          //log(position.toString());
          final comp = createComponent(position);
          add(comp);
        } else {
          log('Unknown spawn point type: ${spawnPoint.class_}');
        }
      }
    }
  }
}
