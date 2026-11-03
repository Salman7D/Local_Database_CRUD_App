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

  Map<String, dynamic> toMap(){
    return{
      "id" : id,
      "name" : name,
      'phone': phone,
      'email': email,
      'address': address,
      'isFavorite': isFavorite,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map){
    return Contact(
        id: map["id"],
        name: map["name"],
        phone: map["phone"],
        email: map["email"],
        address: map["address"],
        isFavorite: map["isFavorite"]
    );
  }
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

  Future<Database> _initDatabase() async {
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

  //create
  Future<int> insertContact(Contact contact) async{
    final db = await instance.database;

    return await db.insert("contacts",
        contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //read
  Future<List<Contact>> getContacts() async{
    final db = await instance.database;

    final result = await db.query(
      "contacts",
      orderBy: "name COLLATE NOCASE ASC",
    );

    return result.map((map) => Contact.fromMap(map)).toList();
  }

  //update
  Future<int> updateContact(Contact contact) async{
    final db = await instance.database;

    return await db.update("contacts",
    contact.toMap(),
        where: "id = ?",
        whereArgs: [contact.id]
    );
}

//delete
  Future<int> deleteContact(int id) async{
    final db = await instance.database;

    return await db.delete("contacts",
      where: "id : ?",
      whereArgs: [id]
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



