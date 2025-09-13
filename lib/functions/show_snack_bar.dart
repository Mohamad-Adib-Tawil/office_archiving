
  import 'package:flutter/material.dart';

void showSnackBar(BuildContext context,String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message,style: TextStyle(color: Color(0xFF40811B)),)),
    );
  }
