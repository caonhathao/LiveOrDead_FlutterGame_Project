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
  final Enemy enemy;
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];

  Level({required this.levelName, required this.player, required this.enemy}) {
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

    final playerLayer = level.tileMap.getLayer<ObjectGroup>('Player');
    if (playerLayer != null) {
      for (final spawnPoint in playerLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(player);
            break;
          default:
            log('Unknown spawn point type: ${spawnPoint.class_}');
        }
      }
    }

        final enemyLayer = level.tileMap.getLayer<ObjectGroup>('Enemy');
    if (enemyLayer != null) {
      for (final spawnPoint in enemyLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Enemy':
            enemy.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(enemy);
            break;
          default:
            log('Unknown spawn point type: ${spawnPoint.class_}');
        }
      }
    }

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
}
