import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class CommentBottomSheet extends StatefulWidget {
  final String videoId;

  const CommentBottomSheet({super.key, required this.videoId});

  static void show(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows it to take up more screen space
      backgroundColor: Colors.grey[900], // Dark mode aesthetic
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.6, // 60% of screen height
              child: CommentBottomSheet(videoId: videoId),
            ),
          ),
    );
  }

  @override
  _CommentBottomSheetState createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  List<dynamic> _comments = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  bool _isPosting = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/ecolearn/feed'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> videos = jsonDecode(res.body);
        final video = videos.firstWhere(
          (v) => v['_id'] == widget.videoId,
          orElse: () => null,
        );
        if (video != null) {
          setState(() {
            _comments = video['comments'] ?? [];
            _error = '';
          });
        }
      }
    } catch (e) {
      setState(() => _error = "Couldn't load comments");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    if (_textController.text.trim().isEmpty) return;
    setState(() => _isPosting = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.post(
        Uri.parse(
          '${ApiService.baseUrl}/api/ecolearn/comment/${widget.videoId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"text": _textController.text.trim()}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _comments = data['comments'] ?? [];
          _textController.clear();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to post comment")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network error")));
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24), // Spacer for alignment
              const Text(
                "Comments",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Comments List
        Expanded(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                  : _error.isNotEmpty
                  ? Center(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                  : _comments.isEmpty
                  ? const Center(
                    child: Text(
                      "No comments yet. Be the first! 🌱",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                c['user']?['username']
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "@${c['user']?['username'] ?? 'anonymous'}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c['text'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(top: BorderSide(color: Colors.grey[800]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Add a thoughtful comment...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[800],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:
                    _isPosting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.green,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.send, color: Colors.green),
                onPressed: _isPosting ? null : _postComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
