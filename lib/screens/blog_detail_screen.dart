import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BlogDetailScreen extends StatefulWidget {
  final String blogId;

  BlogDetailScreen({required this.blogId});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  Map<String, dynamic>? blog;
  String? token;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token != null) {
      _fetchBlog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication token not found")),
      );
    }
  }

  Future<void> _fetchBlog() async {
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:5000/api/blogs/${widget.blogId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          blog = jsonDecode(response.body);
        });
      } else {
        print("Failed to load blog: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load blog")),
        );
      }
    } catch (e) {
      print("Error fetching blog: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading blog")),
      );
    }
  }

  Future<void> _likeBlog() async {
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:5000/api/blogs/${widget.blogId}/like"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        _fetchBlog();
      } else {
        print("Failed to like blog: ${response.statusCode}");
      }
    } catch (e) {
      print("Error liking blog: $e");
    }
  }

  Future<void> _addComment() async {
    if (token == null || commentController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/blogs/${widget.blogId}/comment"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"text": commentController.text}),
      );

      if (response.statusCode == 201) {
        commentController.clear();
        _fetchBlog();
      } else {
        print("Failed to add comment: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add comment")),
        );
      }
    } catch (e) {
      print("Error adding comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding comment")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (blog == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading..."), backgroundColor: Colors.deepPurple),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String author = blog!['author']?['username'] ?? "Unknown";
    int likes = blog!['likes'] is int ? blog!['likes'] : 0;
    int views = blog!['views'] is int ? blog!['views'] : 0;
    List<dynamic> comments = blog!['comments'] is List ? blog!['comments'] : [];

    return Scaffold(
      appBar: AppBar(title: Text(blog!['title'] ?? "Blog"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("By $author", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("$views Views", style: TextStyle(color: Colors.grey)),
            Divider(),
            Text(blog!['content'] ?? "No content available"),
            Divider(),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up, color: Colors.blue),
                  onPressed: _likeBlog,
                ),
                Text("$likes Likes"),
              ],
            ),
            Divider(),
            Text("Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: comments.isNotEmpty
                  ? ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var comment = comments[index];
                        String username = comment is Map && comment['user'] is Map
                            ? (comment['user']['username'] ?? "Anonymous")
                            : "Anonymous";
                        return ListTile(
                          title: Text(comment is Map ? (comment['text'] ?? "No comment text") : "No comment text"),
                          subtitle: Text("By $username"),
                        );
                      },
                    )
                  : Center(child: Text("No comments yet")),
            ),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: "Add a comment...",
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
