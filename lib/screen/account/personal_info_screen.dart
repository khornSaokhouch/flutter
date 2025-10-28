import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  final int user;
  const PersonalInfoScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Info'),
      ),
      body: Center(
        child: Text('User ID: $user'),
      ),
    );
  }
}
