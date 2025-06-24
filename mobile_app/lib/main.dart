import 'package:flutter/material.dart';
import 'src/screens/deals_list_screen.dart'; // Import the DealsListScreen

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
        // primaryColor: const Color(0xFF1A73E8), // Example: Google Blue
        // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.orangeAccent),
        useMaterial3: true, // Using Material 3 design
        colorSchemeSeed: Colors.blueAccent, // Seed color for Material 3
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          // backgroundColor: const Color(0xFF1A73E8),
          // foregroundColor: Colors.white,
          elevation: 2.0,
          titleTextStyle: const TextStyle(
            // color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        )
      ),
      home: const DealsListScreen(), // Set DealsListScreen as the home screen
    );
  }
}
