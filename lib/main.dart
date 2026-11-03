import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main(){
  runApp(contactApp());
}

class Contact{
  final int ? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int isFavorite;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.isFavorite = 0
});
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async{
    if(_database != null)
      return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database?> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "contacts.db");
    return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async{
          await db.execute('''
      CREATE TABLE contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            address TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0
      )
      ''');
        }
    );
  }

}

class contactApp extends StatelessWidget {
  const contactApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Contact Manager",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true
      ),
      home: const ContactHomePage(),
    );
  }
}

class ContactHomePage extends StatelessWidget {
  const ContactHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}



