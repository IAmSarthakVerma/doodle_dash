import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/doodle_dash.dart';

// Overlay that appears for the main menu

class MainMenuOverlay extends StatelessWidget {
  const MainMenuOverlay(this.game, {super.key});

  final Game game;

  // TODO: Definitely style this overlay more

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // TODO: make more idiomatic
    final double menuHeight = screenSize.height > 300 ? 300 : screenSize.height;
    final double menuWidth = screenSize.width > 300 ? 300 : screenSize.width;

    return Material(
      child: Center(
        child: ConstrainedBox(
          // TODO: Also make more idiomatic
          constraints: BoxConstraints.tight(Size(menuWidth, menuHeight)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doodle Dash!',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              ElevatedButton(
                onPressed: () {
                  (game as DoodleDash).startGame();
                },
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(
                    const Size.fromHeight(40),
                  ),
                  textStyle: MaterialStateProperty.all(
                      Theme.of(context).textTheme.titleLarge),
                ),
                child: const Text('Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
