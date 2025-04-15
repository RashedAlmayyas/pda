import 'package:flutter/material.dart';


class MyButtonTheme {
  static final ElevatedButtonThemeData elevatedButtonThemeData =
      ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
      ),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
        const EdgeInsets.all(14.0),
      ),
      backgroundColor:
          WidgetStateProperty.all<Color>(const Color.fromARGB(255, 223, 14, 14)),
      textStyle: WidgetStateProperty.all<TextStyle>(
        const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );

  static final ButtonStyle loginButtonStyle = ButtonStyle(
    shape: WidgetStateProperty.all<OutlinedBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32.0),
      ),
    ),
    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
    textStyle: WidgetStateProperty.all<TextStyle>(
      const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    ),
    foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
  );
}
