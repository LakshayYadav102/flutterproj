import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../widgets/ecolearn_bottom_nav.dart';
import 'ecolearn_single_video_screen.dart'; // ✅ Added import

class CreatorProfileScreen extends StatefulWidget {
  final String userId;

  const CreatorProfileScreen({super.key, required this.userId});

  @override
  _CreatorProfileScreenState createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _creator;
  List<dynamic> _videos = [];
  bool _isFollowing = false;
  bool _followLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      String? token = prefs.getString('token');

      final res = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/api/ecolearn/creator/${widget.userId}',
        ),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _creator = data['creator'];
          _videos = data['videos'] ?? [];
          _isFollowing = data['creator']['isFollowing'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Profile not found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error";
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFollow() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please log in to follow")));
      return;
    }

    setState(() => _followLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/ecolearn/follow/${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isFollowing = data['following'];
          if (_creator != null) {
            _creator!['followersCount'] = data['followersCount'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to follow user")));
    } finally {
      setState(() => _followLoading = false);
    }
  }

  Future<void> _handleDelete(String videoId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text("Delete Video"),
                content: const Text(
                  "Are you sure you want to permanently delete this video?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/api/ecolearn/video/$videoId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          _videos.removeWhere((v) => v['_id'] == videoId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Video deleted")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete video")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    if (_error.isNotEmpty || _creator == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    bool isOwnProfile = _currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "@${_creator!['username']}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[800],
                  backgroundImage:
                      _creator!['profilePic'] != null
                          ? NetworkImage(
                            _creator!['profilePic'].startsWith('http')
                                ? _creator!['profilePic']
                                : '${ApiService.baseUrl}${_creator!['profilePic']}',
                          )
                          : null,
                  child:
                      _creator!['profilePic'] == null
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(height: 15),
                Text(
                  "@${_creator!['username']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          "${_creator!['followersCount'] ?? 0}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Followers",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),
                    Column(
                      children: [
                        Text(
                          "${_creator!['followingCount'] ?? 0}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Following",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isOwnProfile)
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isFollowing ? Colors.grey[800] : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _followLoading ? null : _handleFollow,
                      child:
                          _followLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _isFollowing ? "Following" : "Follow",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),

          // Video Grid
          Expanded(
            child:
                _videos.isEmpty
                    ? const Center(
                      child: Text(
                        "No videos yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        // ✅ FIXED: Navigation added
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EcoLearnSingleVideoScreen(
                                      videoData: video,
                                    ),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                left: 5,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    Text(
                                      "${video['views'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwnProfile)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => _handleDelete(video['_id']),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      // Attached bottom nav here (Only show it if viewing own profile)
      bottomNavigationBar:
          isOwnProfile ? const EcoLearnBottomNav(currentIndex: 3) : null,
    );
  }
}
