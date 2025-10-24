import 'package:flutter/material.dart';

extension ColorArgb on Color {
  int toARGB32() => value; // Color.value is already 0xAARRGGBB
}
