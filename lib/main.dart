import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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



