import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import '/config/mongoservice.dart';
import 'dart:io';

class Display extends StatefulWidget {
  const Display({super.key});

  @override
  State<Display> createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
    searchController.addListener(_filterEmployees);
  }

  void fetchData() async {
    var data = await MongoDatabase.getData();
    setState(() {
      employees = data;
      filteredEmployees = employees; // Initialize filtered list
    });
  }

  void _filterEmployees() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredEmployees = employees
          .where((employee) =>
              employee['fullName'].toLowerCase().contains(query) ||
              (employee['employeeId']?.toString() ?? '').contains(query))
          .toList();
    });
  }

  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    final DateFormat formatter = DateFormat('MMMM d, yyyy, h:mm a');
    return formatter.format(dateTime);
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(employee['fullName'])),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (employee['imagePath'] != null)
                  Image.file(
                    File(employee['imagePath']),
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 10),
                Text('Employee ID: ${employee['employeeId'] ?? 'Unknown'}'),
                Text('Timestamp: ${employee['timestamp'] != null ? _formatTimestamp(employee['timestamp']) : 'Unknown'}'),
                // Add more fields as needed
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registered Employees',style: TextStyle(color: Colors.white),),  backgroundColor: const Color(0xFF3D9260),
      iconTheme: IconThemeData(color: Colors.white),),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Employee',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // Display Employees
          Expanded(
            child: filteredEmployees.isEmpty
                ? const Center(child: Text('No employees found.'))
                : ListView.builder(
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      var employee = filteredEmployees[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text("${employee['fullName']}"),
                          subtitle: Text('Employee ID: ${employee['employeeId'] ?? 'Unknown'}'),
                          onTap: () => _showEmployeeDetails(employee),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}