import 'package:flutter/material.dart';
import 'package:tetris/models/tetromino.dart';
import 'package:tetris/utils/game_constants.dart';
import 'package:tetris/utils/game_utils.dart';

class GameBoard extends StatelessWidget {
  final List<List<int>> board;
  final Tetromino? currentTetromino;
  final int tetrominoX;
  final int tetrominoY;

  GameBoard({required this.board, this.currentTetromino, this.tetrominoX = 0, this.tetrominoY = 0,});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: boardWidth * tileSize.toDouble(),
          height: boardHeight * tileSize.toDouble(),
          child: _buildBoard(),
        ),
      ],
    );
  }



  Widget _buildBoard() {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      itemCount: boardWidth * boardHeight,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: boardWidth,
      ),
      itemBuilder: (BuildContext context, int index) {
        int x = index % boardWidth;
        int y = index ~/ boardWidth;
        int cellValue = board[y][x];

        if (currentTetromino != null) {
          final tetrominoWidth = currentTetromino!.shape[0].length;
          final tetrominoHeight = currentTetromino!.shape.length;

          if (x >= tetrominoX &&
              x < tetrominoX + tetrominoWidth &&
              y >= tetrominoY &&
              y < tetrominoY + tetrominoHeight &&
              currentTetromino!.shape[y - tetrominoY][x - tetrominoX] == 1) {
            cellValue = 1;
          }
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(10),
            color: currentTetromino != null &&
                x >= tetrominoX &&
                x < tetrominoX + currentTetromino!.shape[0].length &&
                y >= tetrominoY &&
                y < tetrominoY + currentTetromino!.shape.length &&
                currentTetromino!.shape[y - tetrominoY][x - tetrominoX] == 1
                ? getColor(currentTetromino!.color)
                : getColor(cellValue),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.2),
            //     blurRadius: 5,
            //     offset: Offset(5, 5),
            //   ),
            // ],

          ),
        );
      },
    );
  }





}
