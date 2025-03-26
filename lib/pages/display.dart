import 'package:flutter/material.dart';
import '/config/mongoservice.dart';

class Display extends StatefulWidget {
  const Display({super.key});

  @override
  State<Display> createState() => _DisplayState();
}

class _DisplayState extends State<Display> {
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    var data = await MongoDatabase.getData();
    setState(() {
      employees = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MongoDB Employees')),
      body: employees.isEmpty
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                var employee = employees[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                  title: Text("${employee['fullName']}"),
                    subtitle: Text('Employee ID: ${employee['emp_id'] ?? 'Unknown'}'),
                  ),
                );
              },
            ),
    );
  }
}
