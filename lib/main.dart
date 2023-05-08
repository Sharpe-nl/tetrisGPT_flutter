import 'package:flutter/material.dart';
import 'widgets/game_controller.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(TetrisGPT());
}

class TetrisGPT extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    ThemeData appTheme = ThemeData(
      primarySwatch: Colors.deepOrange,
      textTheme: GoogleFonts.latoTextTheme(
        Theme.of(context).textTheme,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return MaterialApp(
      title: 'TetrisGPT',
      theme: appTheme,
      home: GameController(),
    );
  }
}
