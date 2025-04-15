import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pda_v1/themes/color_theme.dart';

class MyAppBarTheme {
  static const myAppBarTheme = AppBarTheme(
    backgroundColor: ColorTheme.primaryColor,
    elevation: 4,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    foregroundColor: Colors.white,
  );
}
