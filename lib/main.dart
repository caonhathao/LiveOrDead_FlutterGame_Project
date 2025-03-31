import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:live_or_dead/live_or_dead.dart';
import 'package:flutter/services.dart';
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    ByteData data = await rootBundle.load('assets/tiles/Map_01.tmx');
    log('File loaded successfully! Size: ${data.lengthInBytes} bytes');
  } catch (e) {
    log('Error loading file: $e');
  }

  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  runApp(GameWidget(game: LiveOrDead()));
}
