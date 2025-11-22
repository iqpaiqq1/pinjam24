// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import halaman Login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Peminjaman',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema Ungu sebagai warna utama
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),

        // Card Theme
        cardTheme: const CardThemeData(elevation: 2),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // Halaman awal adalah Login Screen
      home: const LoginScreen(),
    );
  }
}
