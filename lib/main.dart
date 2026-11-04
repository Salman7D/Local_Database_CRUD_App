import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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

  Future<Database> get database async {
    if (_database != null)
      return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, "contacts.db");
    return await openDatabase(
        dbFilePath,
        version: 1,
        onCreate: (db, version) async {
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
  Future<int> insertContact(Contact contact) async {
    final db = await instance.database;

    return await db.insert("contacts",
        contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //read
  Future<List<Contact>> getContacts() async {
    final db = await instance.database;

    final result = await db.query(
      "contacts",
      orderBy: "name COLLATE NOCASE ASC",
    );

    return result.map((map) => Contact.fromMap(map)).toList();
  }

  //update
  Future<int> updateContact(Contact contact) async {
    final db = await instance.database;

    return await db.update("contacts",
        contact.toMap(),
        where: "id = ?",
        whereArgs: [contact.id]
    );
  }

//delete
  Future<int> deleteContact(int id) async {
    final db = await instance.database;

    return await db.delete("contacts",
        where: "id = ?",
        whereArgs: [id]
    );
  }

//favorite
  Future<int> toggleFavorite(Contact contact) async {
    final db = await instance.database;

    final updatedContact = Contact(
        id: contact.id,
        name: contact.name,
        phone: contact.phone,
        email: contact.email,
        address: contact.address,
        isFavorite: contact.isFavorite == 1 ? 0 : 1
    );

    return await updateContact(updatedContact);
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

class ContactHomePage extends StatefulWidget {
  const ContactHomePage({super.key});

  @override
  State<ContactHomePage> createState() => _ContactHomePageState();
}

class _ContactHomePageState extends State<ContactHomePage> {
  List<Contact> contacts = [];

  String searchQuery = '';
  bool showFavoritesOnly = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }


  Future<void> loadContacts() async {
    final result = await DatabaseHelper.instance.getContacts();

    if (!mounted) return;

    setState(() {
      contacts = result;
      isLoading = false;
    });
  }


  Future<void> openContactForm({Contact? contact}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ContactFormDialog(contact: contact);
      },
    );

    if (result == true) {
      await loadContacts();
    }
  }


  Future<void> deleteContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text('Delete ${contact.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && contact.id != null) {
      await DatabaseHelper.instance.deleteContact(contact.id!);
      await loadContacts();
    }
  }

  @override
  Widget build(BuildContext context) {

    final filteredContacts = contacts.where((contact) {
      final matchesSearch = contact.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      final matchesFavorite =
          !showFavoritesOnly || contact.isFavorite == 1;

      return matchesSearch && matchesFavorite;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Show favorites',
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: showFavoritesOnly ? Colors.red : null,
            ),
          ),
        ],
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search contacts by name',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  showFavoritesOnly ? 'Favorite Contacts' : 'All Contacts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text('${filteredContacts.length}'),
              ],
            ),
          ),

          const SizedBox(height: 8),


          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredContacts.isEmpty
                ? const Center(
              child: Text('No contacts found'),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),

                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.indigo.shade50,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    title: Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${contact.phone}\n${contact.email}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    isThreeLine: true,

                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await openContactForm(
                            contact: contact,
                          );
                        } else if (value == 'delete') {
                          await deleteContact(contact);
                        } else if (value == 'favorite') {
                          await DatabaseHelper.instance
                              .toggleFavorite(contact);
                          await loadContacts();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'favorite',
                          child: Text(
                            contact.isFavorite == 1
                                ? 'Remove Favorite'
                                : 'Add to Favorite',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: () => openContactForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ContactFormDialog extends StatefulWidget {
  final Contact? contact;

  const ContactFormDialog({
    super.key,
    this.contact,
  });

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.contact?.name ?? '',
    );

    phoneController = TextEditingController(
      text: widget.contact?.phone ?? '',
    );

    emailController = TextEditingController(
      text: widget.contact?.email ?? '',
    );

    addressController = TextEditingController(
      text: widget.contact?.address ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }


  Future<void> saveContact() async {
    if (!formKey.currentState!.validate()) return;

    final oldContact = widget.contact;

    final contact = Contact(
      id: oldContact?.id,
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
      isFavorite: oldContact?.isFavorite ?? 0,
    );

    if (oldContact == null) {
      await DatabaseHelper.instance.insertContact(contact);
    } else {
      await DatabaseHelper.instance.updateContact(contact);
    }

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Contact' : 'Add Contact'),

      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email';
                  }

                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Address
              TextFormField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saveContact,
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
