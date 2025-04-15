import 'package:pda_v1/themes/app_bar_theme.dart';
import 'package:pda_v1/themes/button_theme.dart';
import 'package:pda_v1/themes/color_theme.dart';
import 'package:pda_v1/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      title: "pda",
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: ColorTheme.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.nunitoSansTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: MyButtonTheme.elevatedButtonThemeData,
        appBarTheme: MyAppBarTheme.myAppBarTheme,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.red),
        useMaterial3: false,
      ),
       home: const LoginPage(),

    );
  }
}
