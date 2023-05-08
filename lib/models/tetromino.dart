import 'dart:math';

import 'package:flutter/material.dart';

class Tetromino {
  final List<List<int>> shape;
  final int color;
  final int rotation;

  Tetromino({required this.shape, required this.color, this.rotation = 0});

  // Tetromino rotate() {
  //   final rotatedShape = List.generate(shape.length, (_) => List.filled(shape.length, 0));
  //   for (int i = 0; i < shape.length; ++i) {
  //     for (int j = 0; j < shape.length; ++j) {
  //       rotatedShape[i][j] = shape[shape.length - j - 1][i];
  //     }
  //   }
  //   return Tetromino(shape: rotatedShape, color: color, rotation: (rotation + 1) % 4);
  // }

  Tetromino rotate() {
    final newWidth = shape.length;
    final newHeight = shape[0].length;
    final rotatedShape = List.generate(newHeight, (_) => List.filled(newWidth, 0));
    for (int i = 0; i < newHeight; ++i) {
      for (int j = 0; j < newWidth; ++j) {
        rotatedShape[i][j] = shape[newWidth - j - 1][i];
      }
    }
    return Tetromino(shape: rotatedShape, color: color, rotation: (rotation + 1) % 4);
  }

}

List<Tetromino> tetrominoes = [
  // I-vorm
  Tetromino(shape: [
    [1, 1, 1, 1],
  ], color: 1),

  // J-vorm
  Tetromino(shape: [
    [1, 1, 1],
    [0, 0, 1],
  ], color: 2),

  // L-vorm
  Tetromino(shape: [
    [1, 1, 1],
    [1, 0, 0],
  ], color: 3),

  // O-vorm
  Tetromino(shape: [
    [1, 1],
    [1, 1],
  ], color: 4),

  // S-vorm
  Tetromino(shape: [
    [0, 1, 1],
    [1, 1, 0],
  ], color: 5),

  // T-vorm
  Tetromino(shape: [
    [1, 1, 1],
    [0, 1, 0],
  ], color: 6),

  // Z-vorm
  Tetromino(shape: [
    [1, 1, 0],
    [0, 1, 1],
  ], color: 7),
];

