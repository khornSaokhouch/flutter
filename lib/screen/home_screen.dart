import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../server/user_serveice.dart';

class UserTestPage extends StatefulWidget {
  final int userId;
  const UserTestPage({super.key, required this.userId});

  @override
  State<UserTestPage> createState() => _UserTestPageState();
}

class _UserTestPageState extends State<UserTestPage> {
  UserModel? user;
  String status = "Loading user data...";

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final result = await UserService.getUserById(widget.userId);
      setState(() {
        user = result;
        status = "User data loaded successfully ✅";
      });
    } catch (e) {
      setState(() {
        status = "Failed to load user: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Test Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (user != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text("No Name"),
                  subtitle: Text("Email 'No Email'}"),
                  trailing: Text("ID"),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchUser,
              child: const Text("Fetch User Again"),
            ),
          ],
        ),
      ),
    );
  }
}
