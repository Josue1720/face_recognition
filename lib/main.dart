import 'package:flutter/material.dart';
import '/pages/Homepage.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Homescreen(),
    );
  }
}

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Centers content vertically
          children: [
            Image.asset(
              'assets/images/face.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20), // Adds space below the image
            const Text(
              "Welcome to Face Recognition",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Homepage(),
                  ), // Navigate to Homepage
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  0xFF007AFF,
                ), // Set the button's background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              ),
              child: Text(
                "Get Started",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
