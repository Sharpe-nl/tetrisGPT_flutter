import 'package:flutter/material.dart';

Color getColor(int index) {
  switch (index) {
    case 1:
      return Colors.cyan.shade900;
    case 2:
      return Colors.blue.shade900;
    case 3:
      return Colors.orange.shade900;
    case 4:
      return Colors.yellow.shade900;
    case 5:
      return Colors.green.shade900;
    case 6:
      return Colors.purple.shade900;
    case 7:
      return Colors.red.shade900;
    default:
      return Colors.grey;
  }
}
