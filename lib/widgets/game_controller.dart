import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tetris/models/tetromino.dart';
import 'package:tetris/utils/game_constants.dart';
import 'package:tetris/widgets/game_board.dart';
import 'package:tetris/utils/game_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameState {
  playing,
  paused,
  game_over,
  stopped,
}

class GameController extends StatefulWidget {
  @override
  _GameControllerState createState() => _GameControllerState();
}

class _GameControllerState extends State<GameController> {
  List<List<int>> _board =
      List.generate(boardHeight, (_) => List.filled(boardWidth, 0));
  Tetromino? _currentTetromino;
  int _tetrominoX = 0;
  int _tetrominoY = 0;
  int _score = 0;
  GameState _gameState = GameState.stopped;
  Timer? _timer;
  Timer? _fastDropTimer;
  Tetromino? _nextTetromino;
  int _highScore = 0;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TetrisGPT'),
        centerTitle: true,
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            double boardSize =
                constraints.maxWidth < constraints.maxHeight * 0.7
                    ? constraints.maxWidth
                    : constraints.maxHeight * 0.7;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      // width: boardSize,
                      // height: boardSize * 2,
                      child: GameBoard(
                        board: _board,
                        currentTetromino: _currentTetromino,
                        tetrominoX: _tetrominoX,
                        tetrominoY: _tetrominoY,
                      ),
                    ),
                    SizedBox(width: 10),
                    // voeg ruimte toe tussen het bord en de rest
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNextTetromino(),
                        SizedBox(height: 30),
                        // voeg ruimte toe tussen de score en het volgende blok
                        _buildScore(),
                        SizedBox(height: 100),
                        _buildStartReset(),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // voeg ruimte toe tussen het bord en de knoppen
                _buildControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return DropdownButton<int>(
      value: _level,
      items: List.generate(10, (index) {
        return DropdownMenuItem<int>(
          value: index + 1,
          child: Text('Level ${index + 1}'),
        );
      }),
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            _level = newValue;
          });
          _pauseGame();
        }
      },
    );
  }

  Widget _buildStartReset() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            IconButton(
              iconSize: 40,
              icon: Icon(Icons.refresh),
              onPressed: () {
                _pauseGame();
                _showResetConfirmationDialog();
              },
            ),
            SizedBox(width: 40),
            IconButton(
              iconSize: 40,
              icon: _gameState == GameState.paused ||
                      _gameState == GameState.stopped
                  ? Icon(Icons.play_arrow)
                  : Icon(Icons.pause),
              onPressed: _gameState == GameState.stopped
                  ? _startGame
                  : _gameState == GameState.paused
                      ? _resumeGame
                      : _pauseGame,
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildLevelSelector(),
            ],
          )
        ]);
  }

  Widget _buildControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          IconButton(
            iconSize: 40,
            icon: Icon(Icons.arrow_left),
            onPressed:
                _gameState == GameState.playing ? () => _move(-1, 0) : null,
          ),
          SizedBox(width: 10),
          Listener(
            onPointerDown: (_) => startFastDrop(),
            onPointerUp: (_) => stopFastDrop(),
            child: IconButton(
              iconSize: 40,
              icon: Icon(Icons.arrow_drop_down),
              onPressed:
                  _gameState == GameState.playing ? () => _move(0, 1) : null,
            ),
          ),
          SizedBox(width: 10),
          IconButton(
            iconSize: 40,
            icon: Icon(Icons.arrow_right),
            onPressed:
                _gameState == GameState.playing ? () => _move(1, 0) : null,
          ),
          SizedBox(width: 40),
          IconButton(
            iconSize: 40,
            icon: Icon(Icons.rotate_left),
            onPressed: _gameState == GameState.playing ? _rotate : null,
          ),
        ])
      ],
    );
  }

  Widget _buildScore() {
    return Column(
      children: [
        Text(
          'Score: $_score',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'High Score: $_highScore',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNextTetromino() {
    return Container(
      width: 100,
      height: 100,
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        itemCount: 4 * 4,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          int x = index % 4;
          int y = index ~/ 4;
          int cellValue = _nextTetromino != null &&
                  x < _nextTetromino!.shape[0].length &&
                  y < _nextTetromino!.shape.length
              ? _nextTetromino!.shape[y][x]
              : 0;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: _nextTetromino != null
                  ? getColorNextTeromino(cellValue, _nextTetromino!.color)
                  : Colors.transparent,
            ),
          );
        },
      ),
    );
  }

  Color getColorNextTeromino(int cellValue, int colorindex) {
    if (cellValue == 0) {
      return Colors.transparent;
    } else {
      return getColor(colorindex);
    }
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _spawnTetromino();
      _timer = Timer.periodic(
          Duration(milliseconds: (initSpeed * (1 / _level)).round()),
          (timer) => _gameLoop());
    });
  }

  void _gameLoop() {
    Duration _gameSpeed =
        Duration(milliseconds: (initSpeed * (1 / _level)).round());
    Future.delayed(_gameSpeed, () {
      if (_gameState == GameState.playing) {
        if (_canMove(0, 1)) {
          _move(0, 1);
        } else {
          _lockTetromino();
          _clearLines();
          _spawnTetromino();
          if (!_canMove(0, 0)) {
            _resetGame();
            _showGameOverDialog();
          }
        }
      }
    });
  }

  void _spawnTetromino() {
    if (_nextTetromino == null) {
      _nextTetromino = tetrominoes[Random().nextInt(tetrominoes.length)];
    }
    _currentTetromino = _nextTetromino;
    _nextTetromino = tetrominoes[Random().nextInt(tetrominoes.length)];
    _tetrominoX = boardWidth ~/ 2 - _currentTetromino!.shape[0].length ~/ 2;
    _tetrominoY = 0;
  }

  bool _canMove(int dx, int dy) {
    if(_currentTetromino == null){
      return false;
    }
    for (int y = 0; y < _currentTetromino!.shape.length; y++) {
      for (int x = 0; x < _currentTetromino!.shape[y].length; x++) {
        if (_currentTetromino!.shape[y][x] == 1) {
          int newX = _tetrominoX + x + dx;
          int newY = _tetrominoY + y + dy;

          if (newX < 0 ||
              newX >= boardWidth ||
              newY < 0 ||
              newY >= boardHeight ||
              _board[newY][newX] != 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _move(int dx, int dy) {
    if (_canMove(dx, dy)) {
      setState(() {
        _tetrominoX += dx;
        _tetrominoY += dy;
      });
    }
  }

  void startFastDrop() {
    if (_gameState == GameState.playing) {
      _fastDropTimer?.cancel(); // Annuleer de huidige timer als die bestaat
      _fastDropTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
        _move(0, 1);
      });
    }
  }

  void stopFastDrop() {
    _fastDropTimer?.cancel();
  }

  bool _canRotate() {
    Tetromino rotatedTetromino = _currentTetromino!.rotate();

    int newWidth = rotatedTetromino.shape[0].length;
    int newHeight = rotatedTetromino.shape.length;

    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        int boardX = _tetrominoX + x;
        int boardY = _tetrominoY + y;

        if (rotatedTetromino.shape[y][x] == 1) {
          if (boardX < 0 || boardX >= boardWidth || boardY >= boardHeight) {
            return false;
          }

          if (boardY >= 0 && _board[boardY][boardX] == 1) {
            return false;
          }
        }
      }
    }

    return true;
  }

  void _rotate() {
    if (_canRotate()) {
      setState(() {
        _currentTetromino = _currentTetromino!.rotate();
      });
    }
  }

  void _lockTetromino() {
    setState(() {
      for (int y = 0; y < _currentTetromino!.shape.length; y++) {
        for (int x = 0; x < _currentTetromino!.shape[y].length; x++) {
          if (_currentTetromino!.shape[y][x] == 1) {
            _board[_tetrominoY + y][_tetrominoX + x] = _currentTetromino!.color;
          }
        }
      }
    });
  }

  void _clearLines() {
    for (int y = 0; y < boardHeight; y++) {
      if (_board[y].every((cell) => cell >= 1)) {
        setState(() {
          _board.removeAt(y);
          _board.insert(0, List.filled(boardWidth, 0));
          _score++;
        });
      }
    }
  }

  void _pauseGame() {
    setState(() {
      _gameState = GameState.paused;
      _timer?.cancel();
    });
  }

  void _resumeGame() {
    setState(() {
      _gameState = GameState.playing;
      _timer = Timer.periodic(
          Duration(milliseconds: (initSpeed * (1 / _level)).round()),
          (timer) => _gameLoop());
    });
  }

  void _resetGame() {
    setState(() {
      _board = List.generate(boardHeight, (_) => List.filled(boardWidth, 0));
      _currentTetromino = null;
      _nextTetromino = null;
      _tetrominoX = 0;
      _tetrominoY = 0;
      _gameState = GameState.stopped;
      _timer?.cancel();
      _score = 0;
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Game Over',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score: $_score',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'High Score: $_highScore',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Restart',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
            TextButton(
              child: Text(
                'Exit',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop(); // sluit de app af
              },
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset Game',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to reset the game?',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              child: Text(
                'No',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resumeGame(); // Resume the game when Cancel is pressed
              },
            ),
            TextButton(
              child: Text(
                'Reset',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<int> _getHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highscore') ?? 0;
  }

  Future<void> _setHighScore(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highscore', score);
  }

  Future<void> _loadHighScore() async {
    int highScore = await _getHighScore();
    setState(() {
      _highScore = highScore;
    });
  }
}
