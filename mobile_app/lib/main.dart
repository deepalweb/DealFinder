import 'package:flutter/material.dart';
// import 'src/screens/deals_list_screen.dart'; // No longer the primary home
import 'src/screens/home_screen.dart'; // Import the new HomeScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deal Finder',
      debugShowCheckedModeBanner: false, // Optional: to hide the debug banner
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple, // Changed seed color for a new look
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 2.0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black87, // Adjusted for Material3 defaults if not using colored AppBar
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2.0, // Slightly more elevation for cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // More rounded cards
          ),
        ),
        inputDecorationTheme: InputDecorationTheme( // Theme for TextField on HomeScreen
          filled: true,
          fillColor: Colors.grey[200],
           border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
           focusedBorder: OutlineInputBorder( // Border when TextField is focused
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        )
      ),
      home: const HomeScreen(), // Set HomeScreen as the new home screen
    );
  }
}
