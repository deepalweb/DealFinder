import 'package:flutter/material.dart';
// import 'src/screens/deals_list_screen.dart'; // No longer the primary home
// import 'src/screens/home_screen.dart'; // HomeScreen will be navigated to after login
import 'src/screens/login_screen.dart'; // Import the LoginScreen

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
        cardTheme: CardThemeData(
          elevation: 2.0, // Slightly more elevation for cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // More rounded cards
          ),
        ),
        inputDecorationTheme: InputDecorationTheme( // Theme for TextField on HomeScreen and LoginScreen
          filled: true,
          fillColor: Colors.grey[200], // Default fill color for text fields
           border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0), // Standardized border radius
            borderSide: BorderSide.none, // No border by default for a cleaner look
          ),
           enabledBorder: OutlineInputBorder( // Border when enabled but not focused
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey[350]!), // Light grey border
          ),
           focusedBorder: OutlineInputBorder( // Border when TextField is focused
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
          // Apply some padding within the text field
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, // Button background color
            foregroundColor: Colors.white, // Button text/icon color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurple, // Text color for TextButtons
          )
        )
      ),
      home: const LoginScreen(), // Set LoginScreen as the initial screen
    );
  }
}
