import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  _BlogListScreenState createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _blogs = [];

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/blogs'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _blogs = jsonDecode(response.body);
          _error = '';
        });
      } else {
        setState(() => _error = 'Failed to load blogs');
      }
    } catch (e) {
      setState(() => _error = 'Network error fetching blogs');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateString) {
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("The Eco Journal"),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // ✅ FIXED: Navigates to the Create Blog Screen
              Navigator.pushNamed(context, '/blogs/create');
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Text(_error, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_blogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No stories published yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Be the first to share your journey.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blogs.length,
      itemBuilder: (context, index) {
        final blog = _blogs[index];
        final String blogId = blog['_id'] ?? index.toString();
        final String excerpt =
            blog['content'] != null
                ? (blog['content'].length > 100
                    ? "${blog['content'].substring(0, 100)}..."
                    : blog['content'])
                : "No content";

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: () {
              // ✅ FIXED: Navigates to the Blog Details Screen, passing the ID
              Navigator.pushNamed(context, '/blogs/detail', arguments: blogId);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    Image.network(
                      "https://picsum.photos/seed/$blogId/600/400",
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundImage: AssetImage(
                                'assets/images/logo.png',
                              ),
                            ), // fallback
                            const SizedBox(width: 8),
                            Text(
                              blog['author']?['username'] ?? "Eco Warrior",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(blog['createdAt'] ?? ''),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        blog['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(excerpt, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 16),

                      // Footer Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${blog['likes'] ?? 0}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${blog['comments']?.length ?? 0}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const Text(
                            "Read More →",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
