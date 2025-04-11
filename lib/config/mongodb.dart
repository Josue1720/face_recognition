import 'dart:developer';


import'package:mongo_dart/mongo_dart.dart';

class MongoDatabase{
  static var db, userCollection;
  static connect() async{
    db = await Db.create("mongodb://172.22.11.240:27017/employee_data");
    await db.open();
    inspect(db);
    userCollection = db.collection("employees");
  }
}