import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';

class SketchLensApp extends StatelessWidget {
  const SketchLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF101114);
    const surface = Color(0xFF1A1C20);
    const accent = Color(0xFFE8C98D);

    return MaterialApp(
      title: 'SketchLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onPrimary: Color(0xFF20190D),
          secondary: Color(0xFFC8C9CC),
          surface: surface,
          onSurface: Color(0xFFF5F3EF),
          outline: Color(0xFF45474D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Color(0xFFF5F3EF),
          centerTitle: false,
          elevation: 0,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: accent,
          thumbColor: accent,
          inactiveTrackColor: Color(0xFF414349),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF34363B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF34363B)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
