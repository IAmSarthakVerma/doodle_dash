import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

import './world.dart';
import 'managers/managers.dart';
import 'sprites/sprites.dart';

enum Character { dash, sparky }

class DoodleDash extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  DoodleDash({super.children});

  late Player player;
  final World _world = World();
  ObjectManager objectManager = ObjectManager();
  LevelManager levelManager = LevelManager();
  GameManager gameManager = GameManager();

  int screenBufferSpace = 300;

  @override
  Future<void> onLoad() async {
    await add(_world);

    // add Game Manager
    await add(gameManager);

    // add the pause button and score keeper
    overlays.add('gameOverlay');

    // add level/difficulty manager
    await add(levelManager);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // stop updating in between games
    if (gameManager.isGameOver) {
      return;
    }

    // show the main menu when the game launches
    // And return so the engine doesn't  update as long as the menu is up.
    if (gameManager.isIntro) {
      overlays.add('mainMenuOverlay');
      return;
    }

    if (gameManager.isPlaying) {
      final Rect worldBounds = Rect.fromLTRB(
        0,
        camera.position.y - screenBufferSpace,
        camera.gameSize.x,
        camera.position.y + _world.size.y,
      );
      camera.worldBounds = worldBounds;

      checkLevelUp();
      // Camera should only follow Dash when she's moving up, if she's following down
      // the camera should stay where it is and NOT follow her down.
      if (player.isMovingDown) {
        camera.worldBounds = Rect.fromLTRB(
          0,
          camera.position.y - screenBufferSpace,
          camera.gameSize.x,
          camera.position.y + _world.size.y,
        );
      }

      // Camera should only follow Dash when she's moving up, if she's falling down
      // the camera should stay where it is and NOT follow her down.
      var isInTopHalfOfScreen = player.position.y <= (_world.size.y / 2);
      if (!player.isMovingDown && isInTopHalfOfScreen) {
        camera.followComponent(player);
      }

      // if Dash falls off screen, game over!
      if (player.position.y >
          camera.position.y +
              _world.size.y +
              player.size.y +
              screenBufferSpace) {
        onLose();
      }
    }
  }

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 241, 247, 249);
  }

  // This method sets (or resets) the camera, dash and platform manager.
  // It is called when you start a game. Resets game state
  void initializeGameStart() {
    //reset score
    gameManager.reset();

    // remove platform if necessary, because a new one is made each time a new
    // game is started.
    if (children.contains(objectManager)) objectManager.removeFromParent();

    levelManager.reset();
    player.reset();

    // Setting the World Bounds for the camera will allow the camera to "move up"
    // but stay fixed horizontally, allowing Dash to go out of camera on one side,
    // and re-appear on the other side.
    camera.worldBounds = Rect.fromLTRB(
      0,
      -_world.size.y, // top of screen is 0, so negative is already off screen
      camera.gameSize.x,
      _world.size.y +
          screenBufferSpace, // makes sure bottom bound of game is below bottom of screen
    );
    camera.followComponent(player);

    // move dash back to the start
    player.position = Vector2(
      (_world.size.x - player.size.x) / 2,
      (_world.size.y - player.size.y) / 2,
    );

    // reset the the platforms
    objectManager = ObjectManager(
        minVerticalDistanceToNextPlatform: levelManager.minDistance,
        maxVerticalDistanceToNextPlatform: levelManager.maxDistance);

    add(objectManager);

    objectManager.configure(levelManager.level, levelManager.difficulty);
  }

  void setCharacter() {
    player = Player(character: gameManager.character);
    player.setJumpSpeed(levelManager.jumpSpeed);
    add(player);
  }

  void startGame() {
    setCharacter();
    initializeGameStart();
    gameManager.state = GameState.playing;
    overlays.remove('mainMenuOverlay');
  }

  void resetGame() {
    startGame();
    overlays.remove('gameOverOverlay');
  }

  void onLose() {
    gameManager.state = GameState.gameOver;
    player.removeFromParent();
    overlays.add('gameOverOverlay');
  }

  void togglePauseState() {
    if (paused) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  void checkLevelUp() {
    if (levelManager.shouldLevelUp(gameManager.score.value)) {
      levelManager.increaseLevel();
      print('Leveled up! ${levelManager.level}');

      // Change config for how platforms are generated
      objectManager.configure(levelManager.level, levelManager.difficulty);

      // Change config for player jump speed
      player.setJumpSpeed(levelManager.jumpSpeed);
    }
  }
}
