import 'package:flutter/material.dart';
import '/pages/scan_face.dart';
import '/pages/add_name.dart';
import '/pages/display.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Face Recognition Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3D9260),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
     /*  drawer: const Sidebar(), */  // Comment out the drawer
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.add,
                      title: "Register Employee",
                      value: "",
                      iconColor: Colors.blue,
                      onTap: () {
                        // Handle Add card tap
                     Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TestAdd()),
);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.list,
                      title: "List of Employees",
                      value: "",
                      iconColor: Colors.orange,
                      onTap: () {
                        // Handle List card tap
                     Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => Display()),
);

                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.qr_code_scanner,
                      title: "Take Attendance",
                      value: "",
                      iconColor: Colors.green,
                      onTap: () {
                        // Handle Scan card tap
                        print("Scan card tapped");Navigator.push(
  context,
  MaterialPageRoute(builder: (context) =>   ScanFaceScreen()),
);
                      
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      title: "Attendance Records",
                      value: "",
                      iconColor: Colors.red,
                      onTap: () {
                        // Handle Attendance card tap
                        print("Attendance card tapped");
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
               CircleAvatar(
  radius: 30, // Increase the CircleAvatar size
  backgroundColor: iconColor.withOpacity(0.2),
  child: Icon(
    icon,
    color: iconColor,
    size: 40, // Increase the icon size
  ),
),

                const SizedBox(height: 16),
            
                // Text Info
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
            
                // Number aligned to the bottom
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}