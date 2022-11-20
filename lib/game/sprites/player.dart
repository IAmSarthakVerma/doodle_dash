import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../doodle_dash.dart';
import 'sprites.dart';

enum PlayerState {
  left,
  right,
  center,
  rocket,
  nooglerCenter,
  nooglerLeft,
  nooglerRight
}

class Player extends SpriteGroupComponent<PlayerState>
    with HasGameRef<DoodleDash>, KeyboardHandler, CollisionCallbacks {
  Player({super.position, required this.character, this.jumpSpeed = 600})
      : super(
          size: Vector2(79, 109),
          anchor: Anchor.center,
          priority: 1,
        );

  Vector2 _velocity = Vector2.zero();

  // used to calculate if the user is moving Dash left (-1) or right (1)
  int _hAxisInput = 0;
  Character character;

  // used to calculate the horizontal movement speed
  final double _gravity = 9; // acceleration pulling Dash down
  double jumpSpeed; // vertical travel speed

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision detection on Dash
    await add(CircleHitbox());

    await _loadCharacterSprites();
    current = PlayerState.center;
  }

  @override
  void update(double dt) {
    if (gameRef.gameManager.isIntro || gameRef.gameManager.isGameOver) return;

    _velocity.x = _hAxisInput * jumpSpeed; // Dash's horizontal velocity
    _velocity.y +=
        _gravity; // Gravity is always acting on Dash's vertical veloctiy

    // infinite side boundaries if Dash's body is off the screen (position is from center)
    if (position.x < size.x / 2) {
      position.x = gameRef.size.x - (size.x / 2);
    }
    if (position.x > gameRef.size.x - (size.x / 2)) {
      position.x = size.x / 2;
    }

    // Calculate Dash's current position based on her velocity over elapsed time
    // since last update cycle
    position += _velocity * dt;
    super.update(dt);
  }

  void reset() {
    _velocity = Vector2.zero();
    current = PlayerState.center;
  }

  // When arrow keys are pressed, change Dash's travel direction + sprite
  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _hAxisInput = 0; // by default not going left or right

    // Player going left
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      if (isWearingHat) {
        current = PlayerState.nooglerLeft;
      } else if (!hasPowerup) {
        current = PlayerState.left;
      }
      _hAxisInput += -1;
    } // Player going right

    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      if (isWearingHat) {
        current = PlayerState.nooglerRight;
      } else if (!hasPowerup) {
        current = PlayerState.right;
      }
      _hAxisInput += 1;
    }

    // should be taken out after development, because its cheating
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      jump();
    }

    return true;
  }

  bool get isMovingDown => _velocity.y > 0;

  bool get hasPowerup =>
      current == PlayerState.rocket ||
      current == PlayerState.nooglerLeft ||
      current == PlayerState.nooglerRight ||
      current == PlayerState.nooglerCenter;

  bool get isInvincible => current == PlayerState.rocket;

  bool get isWearingHat =>
      current == PlayerState.nooglerLeft ||
      current == PlayerState.nooglerRight ||
      current == PlayerState.nooglerCenter;

  // Callback for Dash colliding with another component in the game
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is EnemyPlatform && !isInvincible) {
      gameRef.onLose();
      return;
    }

    // Check if Dash is moving down and collides with a platform from the top
    // this allows Dash to move up _through_ platforms without collision
    bool isMovingDown = _velocity.y > 0;
    bool isCollidingVertically =
        (intersectionPoints.first.y - intersectionPoints.last.y).abs() < 5;

    bool enablePowerUp = false;

    if (!hasPowerup && (other is Rocket || other is NooglerHat)) {
      enablePowerUp = true;
    }

    // Only want Dash to  “jump” when she is falling + collides with the top of a platform
    if (isMovingDown && isCollidingVertically) {
      current = PlayerState.center;
      if (other is NormalPlatform) {
        jump();
        return;
      } else if (other is SpringBoard) {
        jump(specialJumpSpeed: jumpSpeed * 2);
        return;
      } else if (other is BrokenPlatform &&
          other.current == BrokenPlatformState.cracked) {
        jump();
        other.breakPlatform();
        return;
      }

      if (other is Rocket || other is NooglerHat) {
        enablePowerUp = true;
      }
    }

    if (!enablePowerUp) return;

    if (other is Rocket) {
      current = PlayerState.rocket;
      jump(specialJumpSpeed: jumpSpeed * other.jumpSpeedMultiplier);
      return;
    } else if (other is NooglerHat) {
      if (current == PlayerState.center) current = PlayerState.nooglerCenter;
      if (current == PlayerState.left) current = PlayerState.nooglerLeft;
      if (current == PlayerState.right) current = PlayerState.nooglerRight;
      _removePowerupAfterTime(other.activeLengthInMS);
      jump(specialJumpSpeed: jumpSpeed * other.jumpSpeedMultiplier);
      return;
    }
  }

  void _removePowerupAfterTime(int ms) {
    Future.delayed(Duration(milliseconds: ms), () {
      current = PlayerState.center;
    });
  }

  void jump({double? specialJumpSpeed}) {
    // Top left is 0,0 so going "up" is negative
    _velocity.y = specialJumpSpeed != null ? -specialJumpSpeed : -jumpSpeed;
  }

  void setJumpSpeed(double newJumpSpeed) {
    jumpSpeed = newJumpSpeed;
  }

  Future<void> _loadCharacterSprites() async {
    // Load & configure sprite assets
    final left = await gameRef.loadSprite('game/${character.name}_left.png');
    final right = await gameRef.loadSprite('game/${character.name}_right.png');
    final center =
        await gameRef.loadSprite('game/${character.name}_center.png');
    final rocket = await gameRef.loadSprite('game/rocket_4.png');
    final nooglerCenter =
        await gameRef.loadSprite('game/${character.name}_hat_center.png');
    final nooglerLeft =
        await gameRef.loadSprite('game/${character.name}_hat_left.png');
    final nooglerRight =
        await gameRef.loadSprite('game/${character.name}_hat_right.png');

    sprites = <PlayerState, Sprite>{
      PlayerState.left: left,
      PlayerState.right: right,
      PlayerState.center: center,
      PlayerState.rocket: rocket,
      PlayerState.nooglerCenter: nooglerCenter,
      PlayerState.nooglerLeft: nooglerLeft,
      PlayerState.nooglerRight: nooglerRight,
    };
  }
}
