import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'blog_detail_screen.dart';
import 'create_blog_screen.dart';

class BlogListScreen extends StatefulWidget {
  @override
  _BlogListScreenState createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<dynamic> blogs = [];
  String? token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:5000/api/blogs"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      setState(() {
        blogs = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching blogs")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blogs"), backgroundColor: Colors.deepPurple),
      body: ListView.builder(
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          var blog = blogs[index];
          return ListTile(
            title: Text(blog['title'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("By ${blog['author']['username']} • ${blog['views']} views"),
            trailing: Icon(Icons.remove_red_eye, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlogDetailScreen(blogId: blog['_id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateBlogScreen()),
          );
        },
      ),
    );
  }
}
