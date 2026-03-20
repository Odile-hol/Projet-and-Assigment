import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart'; // Import de ton écran

void main() => runApp(const GradeMasterApp());

class GradeMasterApp extends StatelessWidget {
  const GradeMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GradeMaster Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}
