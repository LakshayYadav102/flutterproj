import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import '../api/api_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final String blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _blog;
  bool _hasLiked = false;
  String? _userId;

  final TextEditingController _commentController = TextEditingController();
  bool _isCommenting = false;

  @override
  void initState() {
    super.initState();
    _fetchBlog();
  }

  Future<void> _fetchBlog() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      String? token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/blogs/${widget.blogId}'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _blog = data;
          List<dynamic> likedBy = data['likedBy'] ?? [];
          _hasLiked = likedBy.contains(_userId);
          _error = '';
        });
      } else {
        setState(
          () => _error = "Error fetching blog. It might have been deleted.",
        );
      }
    } catch (e) {
      setState(() => _error = "Network error.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike() async {
    if (_hasLiked) return; // Already liked

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please log in to like")));
      return;
    }

    try {
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/api/blogs/${widget.blogId}/like'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _blog!['likes'] = data['likes'];
          _blog!['likedBy'] = data['likedBy'];
          _hasLiked = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to like")));
    }
  }

  Future<void> _handleComment() async {
    if (_commentController.text.trim().isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please log in to comment")));
      return;
    }

    setState(() => _isCommenting = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/blogs/${widget.blogId}/comment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"text": _commentController.text.trim()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _blog!['comments'].add(data['comment']);
          _commentController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to post comment")));
    } finally {
      setState(() => _isCommenting = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "";
    try {
      DateTime date = DateTime.parse(dateString);
      List<String> months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.green[800]),
        body: Center(
          child: Text(_error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final authorName = _blog!['author']?['username'] ?? "Eco Warrior";
    final comments = _blog!['comments'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("The Eco Journal"),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Image.network(
              "https://picsum.photos/seed/${_blog!['_id']}/1200/600",
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Meta
                  Text(
                    _blog!['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          authorName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${_formatDate(_blog!['createdAt'])} · ${_blog!['views'] ?? 0} Views",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // Blog Content (Renders HTML if provided from ReactQuill)
                  Html(
                    data: _blog!['content'] ?? "No content",
                    style: {
                      "body": Style(
                        fontSize: FontSize(16),
                        lineHeight: const LineHeight(1.6),
                      ),
                      "p": Style(margin: Margins.only(bottom: 15)),
                    },
                  ),

                  const SizedBox(height: 30),

                  // Like Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hasLiked ? Colors.green[100] : Colors.green[800],
                        foregroundColor:
                            _hasLiked ? Colors.green[800] : Colors.white,
                        elevation: _hasLiked ? 0 : 2,
                      ),
                      onPressed: _hasLiked ? null : _handleLike,
                      icon: Icon(
                        _hasLiked ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(
                        _hasLiked
                            ? "Liked (${_blog!['likes']})"
                            : "Applaud this story (${_blog!['likes']})",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Comments Section
                  Text(
                    "Responses (${comments.length})",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Comment Input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "What are your thoughts?",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.all(15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon:
                            _isCommenting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(
                                  Icons.send,
                                  color: Colors.green,
                                  size: 30,
                                ),
                        onPressed: _isCommenting ? null : _handleComment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Comment List
                  ...comments.map((c) {
                    final cAuthor = c['user']?['username'] ?? "Anonymous";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              cAuthor.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cAuthor,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(c['timestamp']),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  c['text'] ?? "",
                                  style: const TextStyle(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
