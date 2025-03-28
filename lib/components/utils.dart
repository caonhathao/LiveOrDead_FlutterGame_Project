bool checkCollision(player, block) {
  final playerX = player.position.x;
  final playerY = player.position.y;
  final playerWidth = player.width;
  final playerHeight = player.height;

  final blockX = block.position.x;
  final blockY = block.position.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  return (playerY < blockY + blockHeight &&
      playerY + playerHeight > blockY &&
      playerX < playerX + blockWidth &&
      playerX + playerWidth > blockX);
}
