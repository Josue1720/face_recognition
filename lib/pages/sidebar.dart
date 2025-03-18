import 'package:face_recognition/pages/add_person.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Center(
              child: Image(
            image: AssetImage("assets/images/sani.png"),
            width: 100, // Adjust size
            height: 100,
          ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add Person'),
            onTap: () {
             Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => AddPerson()),
);

            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Scan Face'),
            onTap: () {
              Navigator.pushNamed(context, '/profile'); // Change route
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_list),
            title: const Text('List of Persons'),
            onTap: () {
              // Handle logout logic
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
