import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class CreateBlogScreen extends StatefulWidget {
  @override
  _CreateBlogScreenState createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  String? token;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      userId = prefs.getString('userId');
    });

    if (token == null || userId == null) {
      print("❌ Authentication Error: Missing Token or User ID");
    } else {
      print("✅ Token Loaded: $token");
      print("✅ User ID Loaded: $userId");
    }
  }

  Future<void> _createBlog() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) return;
    if (token == null || userId == null) {
      print("❌ Error: No authentication token or user ID found.");
      return;
    }

    var response = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/blogs/create"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "title": titleController.text,
        "content": contentController.text,
        "author": userId, // ✅ Send userId with request
        "tags": [],
      }),
    );

    if (response.statusCode == 201) {
      print("✅ Blog Created Successfully!");
      Navigator.pop(context, true);
    } else {
      print("❌ Blog Creation Failed: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Blog"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: "Content"),
              maxLines: 5,
            ),
            ElevatedButton(onPressed: _createBlog, child: Text("Submit")),
          ],
        ),
      ),
    );
  }
}
