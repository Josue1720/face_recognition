import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static const String MONGO_CONN_URL = "mongodb://172.22.11.240:27017/employee_data";
  static const String EMPLOYEE_COLLECTION = "employees";

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
      print("Cant Connect");

    }
  }
}