import 'package:flutter/material.dart';
import '/pages/sidebar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Sample statistics (Replace with real data)
  int totalFacesRecognized = 120;
  int facesRecognizedToday = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Face Recognition Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Total Faces Recognized
            _buildStatCard(
              icon: Icons.face,
              title: "Total Faces Recognized",
              value: totalFacesRecognized.toString(),
              iconColor: Colors.blue,
            ),

            const SizedBox(height: 12),

            // Faces Recognized Today
            _buildStatCard(
              icon: Icons.check_circle,
              title: "Faces Recognized Today",
              value: facesRecognizedToday.toString(),
              iconColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // Widget to create a modern statistics card
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            // Number aligned to the right
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
