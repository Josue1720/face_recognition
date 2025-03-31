import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static const String MONGO_CONN_URL = "mongodb://172.22.11.240:27017/employee_data";
  static const String EMPLOYEE_COLLECTION = "employees";

  // Fetch all employee data
  static Future<List<Map<String, dynamic>>> getData() async {
    try {
      var db = await Db.create(MONGO_CONN_URL);
      await db.open();
      print("Connected to MongoDB!");

      var collection = db.collection(EMPLOYEE_COLLECTION);
      var data = await collection.find().toList();
      await db.close();
      return data;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  // Insert new employee data
  static Future<void> insertData(Map<String, dynamic> data) async {
    try {
      var db = await Db.create(MONGO_CONN_URL);
      await db.open();
      print("Connected to MongoDB!");

      var collection = db.collection(EMPLOYEE_COLLECTION);
      await collection.insert(data);

      await db.close();
    } catch (e) {
      print("Error: $e");
      print("Cannot Connect");
    }
  }

  // Fetch embeddings for comparison
  static Future<List<Map<String, dynamic>>> getEmbeddings() async {
    try {
      var db = await Db.create(MONGO_CONN_URL);
      await db.open();
      print("Connected to MongoDB!");

      var collection = db.collection(EMPLOYEE_COLLECTION);
      var embeddings = await collection.find({
        "faceEmbeddings": {"\$exists": true} // Fetch only documents with embeddings
      }).toList();

      await db.close();
      return embeddings;
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  // Compare embeddings
  static bool compareEmbeddings(List<dynamic> detected, List<dynamic> stored) {
    if (detected.length != stored.length) return false;

    double distance = 0.0;
    for (int i = 0; i < detected.length; i++) {
      distance += (detected[i] - stored[i]) * (detected[i] - stored[i]);
    }

    // Threshold for similarity (adjust as needed)
    return distance < 0.6;
  }
}