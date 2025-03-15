import 'package:flutter/material.dart';
import '/pages/sidebar.dart';
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: Text("Face Recognition", style: TextStyle(color: Colors.white),
       ),
       backgroundColor: Colors.blue,
       centerTitle: true,
       iconTheme: IconThemeData(color: Colors.white),),
      drawer: Sidebar(),
      body: Center(
        child: Text("This is the Homepage of the Camera")
      ),
    );
  }
}